defmodule WorthAsking.Moderation do
  @moduledoc """
  The Moderation context - manages reports and user blocks.
  """

  import Ecto.Query
  alias WorthAsking.Repo
  alias WorthAsking.Moderation.{Report, Block}

  # Reports

  def create_report(%{id: reporter_id}, attrs) do
    %Report{reporter_id: reporter_id}
    |> Report.changeset(attrs)
    |> Repo.insert()
  end

  def list_pending_reports do
    Report
    |> where(status: :pending)
    |> order_by(asc: :inserted_at)
    |> preload([:reporter, :reported_user])
    |> Repo.all()
  end

  def resolve_report(%Report{} = report, attrs) do
    report
    |> Report.changeset(attrs)
    |> Repo.update()
  end

  # Blocks

  def block_user(blocker_id, blocked_id) do
    %Block{}
    |> Block.changeset(%{blocker_id: blocker_id, blocked_id: blocked_id})
    |> Repo.insert()
  end

  def unblock_user(blocker_id, blocked_id) do
    Block
    |> where(blocker_id: ^blocker_id, blocked_id: ^blocked_id)
    |> Repo.delete_all()

    :ok
  end

  def blocked?(user_id_1, user_id_2) do
    Block
    |> where(
      [b],
      (b.blocker_id == ^user_id_1 and b.blocked_id == ^user_id_2) or
        (b.blocker_id == ^user_id_2 and b.blocked_id == ^user_id_1)
    )
    |> Repo.exists?()
  end

  def list_blocks(user_id) do
    Block
    |> where([b], b.blocker_id == ^user_id)
    |> preload(:blocked)
    |> Repo.all()
  end
end
