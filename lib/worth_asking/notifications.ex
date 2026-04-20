defmodule WorthAsking.Notifications do
  @moduledoc """
  Handles contributor notification pipeline with staggered waves.

  Wave strategy:
  - Basic/Interactive: Wave 1 (5 contributors, immediate) → Wave 2 (3 more, +10min) → Wave 3 (3 more, +30min)
  - Fast Perspective: Wave 1 (3 contributors, immediate) → Wave 2 (3 more, +2min) → Wave 3 (3 more, +5min)
  """

  import Ecto.Query
  alias WorthAsking.Repo
  alias WorthAsking.Contributors.Profile
  alias WorthAsking.Moderation.Block
  alias WorthAsking.Notifications.NotificationWave
  alias WorthAsking.Accounts.UserNotifier

  @wave_sizes %{
    "basic" => [5, 3, 3],
    "interactive" => [5, 3, 3],
    "fast" => [3, 3, 3]
  }

  @wave_delays_ms %{
    "basic" => [0, 10 * 60_000, 30 * 60_000],
    "interactive" => [0, 10 * 60_000, 30 * 60_000],
    "fast" => [0, 2 * 60_000, 5 * 60_000]
  }

  def wave_sizes, do: @wave_sizes
  def wave_delays_ms, do: @wave_delays_ms

  @doc """
  Start the notification pipeline for a new question.
  Finds eligible contributors and sends Wave 1 immediately.
  Schedules subsequent waves via the NotificationWorker.
  """
  def notify_for_question(question) do
    session_type = question.session_type || "basic"
    category = question.category

    eligible = list_eligible_contributors(category, session_type, [], question.user_id)
    sizes = Map.get(@wave_sizes, session_type, [5, 3, 3])
    delays = Map.get(@wave_delays_ms, session_type, [0, 10 * 60_000, 30 * 60_000])

    # Split eligible contributors into waves
    {waves, _remaining} =
      Enum.reduce(Enum.with_index(sizes, 1), {[], eligible}, fn {size, wave_num}, {acc, pool} ->
        {batch, rest} = Enum.split(pool, size)
        wave = %{wave_number: wave_num, contributors: batch}
        {acc ++ [wave], rest}
      end)

    # Send Wave 1 immediately
    case List.first(waves) do
      %{contributors: contributors} when contributors != [] ->
        send_wave(question, 1, contributors)

      _ ->
        :no_eligible_contributors
    end

    # Schedule subsequent waves
    waves
    |> Enum.zip(delays)
    |> Enum.drop(1)
    |> Enum.each(fn {%{wave_number: wave_num, contributors: contributors}, delay_ms} ->
      if contributors != [] do
        WorthAsking.Notifications.Worker.schedule_wave(
          question.id,
          wave_num,
          Enum.map(contributors, & &1.id),
          delay_ms
        )
      end
    end)

    :ok
  end

  @doc """
  Send notifications to a batch of contributors for a specific wave.
  """
  def send_wave(question, wave_number, contributors) do
    contributor_ids = Enum.map(contributors, & &1.id)

    # Record the wave
    %NotificationWave{}
    |> NotificationWave.changeset(%{
      wave_number: wave_number,
      contributor_ids: contributor_ids,
      notified_at: DateTime.utc_now(:second),
      status: "sent"
    })
    |> Ecto.Changeset.put_assoc(:question, question)
    |> Repo.insert(on_conflict: :nothing)

    # Send email to each contributor
    contributors
    |> Repo.preload(:user)
    |> Enum.each(fn profile ->
      UserNotifier.deliver_question_notification(
        profile.user,
        question
      )
    end)

    # Broadcast via PubSub so online contributors see it live
    Enum.each(contributors, fn profile ->
      Phoenix.PubSub.broadcast(
        WorthAsking.PubSub,
        "contributor:#{profile.user_id}",
        {:new_question_alert, question}
      )
    end)

    :ok
  end

  @doc """
  Execute a scheduled wave by wave number.
  Only sends if the question is still pending (not yet assigned/answered).
  """
  def execute_wave(question_id, wave_number, contributor_ids) do
    question = WorthAsking.Questions.get_question!(question_id)

    if question.status == :pending and is_nil(question.assigned_contributor_id) do
      profiles =
        Profile
        |> where([p], p.id in ^contributor_ids)
        |> Repo.all()
        |> Enum.filter(&Profile.available?/1)

      if profiles != [] do
        send_wave(question, wave_number, profiles)
      end
    end

    :ok
  end

  @doc """
  Assign a question to a contributor (session lock).
  """
  def accept_session(question_id, contributor_profile) do
    question = WorthAsking.Questions.get_question!(question_id)

    cond do
      question.status != :pending ->
        {:error, :already_assigned}

      not is_nil(question.assigned_contributor_id) ->
        {:error, :already_assigned}

      not Profile.available?(contributor_profile) ->
        {:error, :not_available}

      true ->
        Ecto.Multi.new()
        |> Ecto.Multi.update(:question,
          Ecto.Changeset.change(question,
            assigned_contributor_id: contributor_profile.user_id,
            assigned_at: DateTime.utc_now(:second)
          )
        )
        |> Ecto.Multi.update(:profile,
          Ecto.Changeset.change(contributor_profile,
            active_session_count: contributor_profile.active_session_count + 1
          )
        )
        |> Repo.transaction()
        |> case do
          {:ok, %{question: question}} -> {:ok, question}
          {:error, _step, changeset, _} -> {:error, changeset}
        end
    end
  end

  @doc """
  Release a session after a contributor submits their response.
  """
  def release_session(contributor_profile) do
    new_count = max(contributor_profile.active_session_count - 1, 0)

    contributor_profile
    |> Ecto.Changeset.change(active_session_count: new_count)
    |> Repo.update()
  end

  @doc """
  List eligible contributors for a category and session type.
  Excludes already-notified contributor IDs and contributors blocked by/blocking the asker.
  Returns profiles ordered by fewest responses (fair distribution).
  """
  def list_eligible_contributors(category, session_type, exclude_ids, asker_user_id \\ nil) do
    category_str = to_string(category)

    blocked_user_ids =
      if asker_user_id do
        Block
        |> where([b], b.blocker_id == ^asker_user_id or b.blocked_id == ^asker_user_id)
        |> select([b], %{blocker_id: b.blocker_id, blocked_id: b.blocked_id})
        |> Repo.all()
        |> Enum.flat_map(fn block -> [block.blocker_id, block.blocked_id] end)
        |> Enum.reject(&(&1 == asker_user_id))
        |> Enum.uniq()
      else
        []
      end

    Profile
    |> where([p], p.application_status == :approved)
    |> where([p], p.available_now == true)
    |> where([p], p.id not in ^exclude_ids)
    |> then(fn query ->
      if blocked_user_ids == [] do
        query
      else
        where(query, [p], p.user_id not in ^blocked_user_ids)
      end
    end)
    |> Repo.all()
    |> Enum.filter(fn p ->
      category_str in Enum.map(p.categories, &to_string/1) &&
        Profile.accepts_session_type?(p, session_type) &&
        Profile.available?(p)
    end)
    |> Enum.sort_by(& &1.response_count)
  end

  @doc """
  Toggle contributor availability. Auto-expires after `hours` (default 4).
  """
  def toggle_availability(profile, available, hours \\ 4) do
    attrs =
      if available do
        %{
          available_now: true,
          available_until: DateTime.add(DateTime.utc_now(), hours * 3600, :second)
        }
      else
        %{available_now: false, available_until: nil}
      end

    profile
    |> Profile.availability_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Update session type preferences.
  """
  def update_session_preferences(profile, attrs) do
    profile
    |> Profile.availability_changeset(attrs)
    |> Repo.update()
  end
end
