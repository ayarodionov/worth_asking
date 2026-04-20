defmodule WorthAsking.Admin do
  @moduledoc """
  Admin context — completely separate from user accounts.
  """

  import Ecto.Query
  alias WorthAsking.Repo
  alias WorthAsking.Admin.Admin

  def get_admin_by_email(email) when is_binary(email) do
    Repo.get_by(Admin, email: email)
  end

  def get_admin_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    admin = Repo.get_by(Admin, email: email)
    if Admin.valid_password?(admin, password), do: admin
  end

  def get_admin!(id), do: Repo.get!(Admin, id)

  def create_admin(attrs) do
    %Admin{}
    |> Admin.registration_changeset(attrs)
    |> Repo.insert()
  end

  # --- Session tokens ---

  @session_validity_in_days 7
  @hash_algorithm :sha256
  @rand_size 32

  def generate_admin_session_token(admin) do
    token = :crypto.strong_rand_bytes(@rand_size)
    hashed = :crypto.hash(@hash_algorithm, token)

    %WorthAsking.Admin.AdminToken{
      token: hashed,
      context: "session",
      admin_id: admin.id
    }
    |> Repo.insert!()

    token
  end

  def get_admin_by_session_token(token) do
    hashed = :crypto.hash(@hash_algorithm, token)

    query =
      from t in WorthAsking.Admin.AdminToken,
        where: t.token == ^hashed and t.context == "session",
        where: t.inserted_at > ago(@session_validity_in_days, "day"),
        join: a in assoc(t, :admin),
        select: a

    Repo.one(query)
  end

  def delete_admin_session_token(token) do
    hashed = :crypto.hash(@hash_algorithm, token)
    Repo.delete_all(from t in WorthAsking.Admin.AdminToken, where: t.token == ^hashed and t.context == "session")
    :ok
  end
end
