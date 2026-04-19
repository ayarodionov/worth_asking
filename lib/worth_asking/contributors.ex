defmodule WorthAsking.Contributors do
  @moduledoc """
  The Contributors context - manages contributor profiles.
  """

  import Ecto.Query
  alias Ecto.Multi
  alias WorthAsking.Repo
  alias WorthAsking.Contributors.Profile
  alias WorthAsking.Questions.{Response, Rating}

  def get_profile_by_user(user_id) do
    Repo.get_by(Profile, user_id: user_id)
  end

  def create_profile(user, attrs) do
    %Profile{}
    |> Profile.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Repo.insert()
  end

  def update_profile(profile, attrs) do
    profile
    |> Profile.changeset(attrs)
    |> Repo.update()
  end

  def list_verified_contributors_for_category(category) do
    Profile
    |> where([p], p.verified == true and ^to_string(category) in p.categories)
    |> preload(:user)
    |> Repo.all()
  end

  def apply_as_contributor(user, attrs) do
    %Profile{user_id: user.id}
    |> Profile.application_changeset(attrs)
    |> Repo.insert()
  end

  def approve_contributor(%Profile{} = profile) do
    profile = Repo.preload(profile, :user)

    Multi.new()
    |> Multi.update(:profile,
      Ecto.Changeset.change(profile, application_status: :approved, verified: true)
    )
    |> Multi.update(:user,
      Ecto.Changeset.change(profile.user, role: :contributor)
    )
    |> Repo.transaction()
    |> case do
      {:ok, %{profile: profile}} -> {:ok, profile}
      {:error, _step, changeset, _changes} -> {:error, changeset}
    end
  end

  def reject_contributor(%Profile{} = profile) do
    profile
    |> Ecto.Changeset.change(application_status: :rejected)
    |> Repo.update()
  end

  def list_pending_applications do
    Profile
    |> where(application_status: :pending)
    |> preload(:user)
    |> Repo.all()
  end

  def update_profile_stats(user_id) do
    profile = Repo.get_by!(Profile, user_id: user_id)

    stats =
      from(r in Response,
        where: r.contributor_id == ^user_id,
        left_join: rt in Rating,
        on: rt.response_id == r.id,
        select: %{
          response_count: count(r.id, :distinct),
          average_rating: avg(rt.score)
        }
      )
      |> Repo.one()

    profile
    |> Profile.stats_changeset(%{
      response_count: stats.response_count,
      average_rating: stats.average_rating && stats.average_rating |> Decimal.to_float()
    })
    |> Repo.update()
  end
end
