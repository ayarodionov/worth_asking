defmodule WorthAsking.Questions do
  @moduledoc """
  The Questions context - manages questions, responses, payments, and ratings.
  """

  import Ecto.Query
  alias WorthAsking.Repo
  alias WorthAsking.Questions.{Question, Response, Payment, Rating}
  alias WorthAsking.Moderation.Block

  # Questions

  def list_questions_for_user(user_id) do
    Question
    |> where(user_id: ^user_id)
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  def list_pending_questions_by_category(category) do
    Question
    |> where(category: ^category, status: :pending)
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
    result =
      %Response{}
      |> Response.changeset(attrs)
      |> Ecto.Changeset.put_assoc(:question, question)
      |> Ecto.Changeset.put_assoc(:contributor, contributor)
      |> Repo.insert()

    case result do
      {:ok, response} ->
        Phoenix.PubSub.broadcast(
          WorthAsking.PubSub,
          "question:#{question.id}",
          {:new_response, response}
        )

        {:ok, response}

      error ->
        error
    end
  end

  def count_responses(question_id) do
    Response
    |> where(question_id: ^question_id)
    |> Repo.aggregate(:count)
  end

  def list_available_questions_for_contributor(profile) do
    contributor_user_id = profile.user_id
    categories = profile.categories |> Enum.map(&to_string/1)

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
    |> where([q], q.status == :pending and q.category in ^categories)
    |> then(fn query ->
      if blocked_user_ids == [] do
        query
      else
        where(query, [q], q.user_id not in ^blocked_user_ids)
      end
    end)
    |> order_by(asc: :inserted_at)
    |> Repo.all()
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
end
