defmodule WorthAsking.Questions do
  @moduledoc """
  The Questions context - manages questions, responses, payments, and ratings.
  """

  import Ecto.Query
  alias WorthAsking.Repo
  alias WorthAsking.Questions.{Question, Response, Payment, Rating, ResponseInteraction}
  alias WorthAsking.Moderation.Block

  @max_responses_per_question 3

  # Questions

  def list_questions_for_user(user_id) do
    Question
    |> where(user_id: ^user_id)
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  def list_pending_questions_by_category(category) do
    Question
    |> where([q], q.category == ^category and q.status in [:pending, :paid])
    |> order_by(asc: :inserted_at)
    |> Repo.all()
  end

  def get_question!(id), do: Repo.get!(Question, id)

  def get_question_with_responses!(id) do
    Question
    |> Repo.get!(id)
    |> Repo.preload(responses: :ratings)
  end

  def create_question(user, attrs) do
    result =
      %Question{}
      |> Question.changeset(attrs)
      |> Ecto.Changeset.put_assoc(:user, user)
      |> Repo.insert()

    case result do
      {:ok, question} ->
        Phoenix.PubSub.broadcast(
          WorthAsking.PubSub,
          "questions:#{question.category}",
          {:new_question, question}
        )

        # Trigger notification pipeline
        Task.start(fn ->
          WorthAsking.Notifications.notify_for_question(question)
        end)

        {:ok, question}

      error ->
        error
    end
  end

  def update_question_status(question, status) do
    question
    |> Ecto.Changeset.change(status: status)
    |> Repo.update()
  end

  # Responses

  def create_response(question, contributor, attrs) do
    # Enforce max 3 responses per question
    current_count = count_responses(question.id)

    if current_count >= @max_responses_per_question do
      {:error, :question_full}
    else
      result =
        %Response{}
        |> Response.changeset(attrs)
        |> Ecto.Changeset.put_assoc(:question, question)
        |> Ecto.Changeset.put_assoc(:contributor, contributor)
        |> Repo.insert()

      case result do
        {:ok, response} ->
          # Auto-close question when it reaches max responses
          new_count = current_count + 1

          if new_count >= @max_responses_per_question do
            update_question_status(question, :answered)
          end

          Phoenix.PubSub.broadcast(
            WorthAsking.PubSub,
            "question:#{question.id}",
            {:new_response, response}
          )

          Phoenix.PubSub.broadcast(
            WorthAsking.PubSub,
            "user:#{question.user_id}",
            {:response_ready, question}
          )

          {:ok, response}

        error ->
          error
      end
    end
  end

  def count_responses(question_id) do
    Response
    |> where(question_id: ^question_id)
    |> Repo.aggregate(:count)
  end

  def list_available_questions_for_contributor(profile) do
    contributor_user_id = profile.user_id
    contributor_categories = profile.categories

    blocked_user_ids =
      Block
      |> where(
        [b],
        b.blocker_id == ^contributor_user_id or b.blocked_id == ^contributor_user_id
      )
      |> select([b], %{blocker_id: b.blocker_id, blocked_id: b.blocked_id})
      |> Repo.all()
      |> Enum.flat_map(fn block ->
        [block.blocker_id, block.blocked_id]
      end)
      |> Enum.reject(&(&1 == contributor_user_id))
      |> Enum.uniq()

    Question
    |> where([q], q.status in [:pending, :paid])
    |> then(fn query ->
      if blocked_user_ids == [] do
        query
      else
        where(query, [q], q.user_id not in ^blocked_user_ids)
      end
    end)
    |> order_by(asc: :inserted_at)
    |> Repo.all()
    |> Enum.filter(fn q ->
      WorthAsking.Categories.matches?(contributor_categories, q.category)
    end)
  end

  def list_responses_by_contributor(user_id) do
    Response
    |> where(contributor_id: ^user_id)
    |> preload([:question, :ratings])
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  # Payments

  def create_payment(question, user, amount_cents) do
    %Payment{}
    |> Payment.changeset(%{amount_cents: amount_cents})
    |> Ecto.Changeset.put_assoc(:question, question)
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Repo.insert()
  end

  def question_paid?(question_id, user_id) do
    Payment
    |> where(question_id: ^question_id, user_id: ^user_id, status: :completed)
    |> Repo.exists?()
  end

  # Ratings

  def rate_response(response, user, score) do
    %Rating{}
    |> Rating.changeset(%{score: score})
    |> Ecto.Changeset.put_assoc(:response, response)
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Repo.insert(
      on_conflict: {:replace, [:score, :updated_at]},
      conflict_target: [:response_id, :user_id]
    )
  end

  # Response interactions (like/save)

  def toggle_interaction(response_id, user_id, type) when type in ["like", "save"] do
    case Repo.get_by(ResponseInteraction, response_id: response_id, user_id: user_id, type: type) do
      nil ->
        %ResponseInteraction{}
        |> ResponseInteraction.changeset(%{type: type})
        |> Ecto.Changeset.put_change(:response_id, response_id)
        |> Ecto.Changeset.put_change(:user_id, user_id)
        |> Repo.insert()

      existing ->
        Repo.delete(existing)
        {:ok, :removed}
    end
  end

  def list_interactions_for_user(user_id, response_ids) when is_list(response_ids) do
    ResponseInteraction
    |> where([i], i.user_id == ^user_id and i.response_id in ^response_ids)
    |> Repo.all()
    |> Enum.group_by(& &1.response_id)
  end

  def question_full?(question_id) do
    count_responses(question_id) >= @max_responses_per_question
  end

  def has_active_question?(user_id) do
    Question
    |> where([q], q.user_id == ^user_id and q.status in [:pending, :paid])
    |> Repo.exists?()
  end

  def get_question_with_responses_and_interactions!(id, user_id) do
    question = get_question_with_responses!(id)
    response_ids = Enum.map(question.responses, & &1.id)
    interactions = list_interactions_for_user(user_id, response_ids)
    {question, interactions}
  end
end
