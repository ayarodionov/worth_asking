defmodule WorthAsking.Contributors.Profile do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "contributor_profiles" do
    field :display_name, :string
    field :bio, :string
    field :categories, {:array, Ecto.Enum},
      values: [
        # Current categories
        :dating_attraction, :relationships, :marriage_long_term, :sex_intimacy,
        :communication, :social_situational, :work_professional,
        :appearance_lifestyle, :general,
        # Legacy values
        :dating, :appearance, :work, :social_situations, :breakups,
        :first_impressions, :style, :dating_dynamics
      ]
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
    field :age_range, :string
    field :location, :string
    field :onboarding_completed, :boolean, default: false
    field :sms_opt_in, :boolean, default: false
    field :availability_preference, :string, default: "anytime"
    field :agreed_to_terms, :boolean, default: false

    # Availability & session preferences
    field :available_now, :boolean, default: false
    field :available_until, :utc_datetime
    field :accept_basic, :boolean, default: true
    field :accept_interactive, :boolean, default: true
    field :accept_fast, :boolean, default: false
    field :active_session_count, :integer, default: 0
    field :max_active_sessions, :integer, default: 2

    # Admin moderation
    field :paused, :boolean, default: false
    field :paused_reason, :string
    field :paused_at, :utc_datetime

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

  def onboarding_changeset(profile, attrs) do
    profile
    |> cast(attrs, [
      :display_name, :bio, :age_range, :location, :avatar_path,
      :sms_opt_in, :availability_preference, :agreed_to_terms, :onboarding_completed
    ])
    |> validate_required([:display_name, :agreed_to_terms])
    |> validate_length(:display_name, min: 2, max: 50)
    |> validate_length(:bio, max: 500)
    |> validate_inclusion(:age_range, ["18-24", "25-34", "35-44", "45-54", "55+"])
    |> validate_inclusion(:availability_preference, ["anytime", "daytime", "evenings", "limited"])
    |> validate_acceptance(:agreed_to_terms)
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
      not profile.paused &&
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
