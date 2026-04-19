defmodule WorthAsking.Contributors.Profile do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "contributor_profiles" do
    field :display_name, :string
    field :bio, :string
    field :categories, {:array, Ecto.Enum},
      values: [:communication, :first_impressions, :style, :dating_dynamics]
    field :specialties, {:array, :string}, default: []
    field :verified, :boolean, default: false
    field :stripe_connect_id, :string
    field :application_status, Ecto.Enum,
      values: [:pending, :approved, :rejected],
      default: :pending
    field :sample_responses, :map, default: %{}
    field :earnings_cents, :integer, default: 0
    field :response_count, :integer, default: 0
    field :average_rating, :float
    field :avatar_path, :string

    # Availability & session preferences
    field :available_now, :boolean, default: false
    field :available_until, :utc_datetime
    field :accept_basic, :boolean, default: true
    field :accept_interactive, :boolean, default: true
    field :accept_fast, :boolean, default: false
    field :active_session_count, :integer, default: 0
    field :max_active_sessions, :integer, default: 2

    belongs_to :user, WorthAsking.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(profile, attrs) do
    profile
    |> cast(attrs, [:bio, :categories, :verified, :stripe_connect_id, :display_name, :specialties, :avatar_path])
    |> validate_required([:categories, :display_name])
    |> validate_length(:bio, max: 500)
    |> validate_length(:display_name, min: 2, max: 50)
  end

  def application_changeset(profile, attrs) do
    profile
    |> cast(attrs, [:display_name, :bio, :categories, :sample_responses, :avatar_path])
    |> validate_required([:display_name, :categories, :sample_responses])
    |> validate_length(:display_name, min: 2, max: 50)
    |> validate_length(:bio, max: 500)
    |> validate_sample_responses()
  end

  defp validate_sample_responses(changeset) do
    case get_field(changeset, :sample_responses) do
      %{"scenarios" => scenarios} when is_list(scenarios) and length(scenarios) >= 2 ->
        changeset

      responses when is_map(responses) and map_size(responses) >= 2 ->
        changeset

      _ ->
        add_error(changeset, :sample_responses, "must include at least 2 sample responses")
    end
  end

  def availability_changeset(profile, attrs) do
    profile
    |> cast(attrs, [:available_now, :available_until, :accept_basic, :accept_interactive, :accept_fast])
  end

  def stats_changeset(profile, attrs) do
    profile
    |> cast(attrs, [:average_rating, :response_count, :earnings_cents])
  end

  def available?(%__MODULE__{} = profile) do
    profile.available_now &&
      profile.application_status == :approved &&
      profile.active_session_count < profile.max_active_sessions &&
      (is_nil(profile.available_until) || DateTime.compare(profile.available_until, DateTime.utc_now()) == :gt)
  end

  def accepts_session_type?(%__MODULE__{} = profile, session_type) do
    case session_type do
      "basic" -> profile.accept_basic
      "interactive" -> profile.accept_interactive
      "fast" -> profile.accept_fast
      _ -> profile.accept_basic
    end
  end
end
