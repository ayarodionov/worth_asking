defmodule WorthAskingWeb.AdvisorRegistrationController do
  use WorthAskingWeb, :controller

  alias WorthAsking.Accounts
  alias WorthAsking.Accounts.User

  def new(conn, _params) do
    changeset = Accounts.change_user_email(%User{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"user" => %{"email" => email}}) do
    email = String.trim(email)

    if email != "" and String.contains?(email, "@") do
      token = Phoenix.Token.sign(conn, "applicant_email", email)
      redirect(conn, to: ~p"/contributors/apply?token=#{token}")
    else
      changeset =
        %User{}
        |> Accounts.change_user_email(%{email: email})
        |> Map.put(:action, :validate)

      render(conn, :new, changeset: changeset)
    end
  end
end
