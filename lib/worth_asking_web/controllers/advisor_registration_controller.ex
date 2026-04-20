defmodule WorthAskingWeb.AdvisorRegistrationController do
  use WorthAskingWeb, :controller

  alias WorthAsking.Accounts
  alias WorthAsking.Accounts.User

  def new(conn, _params) do
    # If already logged in, skip straight to the application
    if conn.assigns.current_scope && conn.assigns.current_scope.user do
      conn
      |> redirect(to: ~p"/contributors/apply")
    else
      changeset = Accounts.change_user_email(%User{})
      render(conn, :new, changeset: changeset)
    end
  end

  def create(conn, %{"user" => %{"email" => email}}) do
    # If already logged in, skip straight to the application
    if conn.assigns.current_scope && conn.assigns.current_scope.user do
      conn
      |> redirect(to: ~p"/contributors/apply")
    else
      user =
        case Accounts.get_user_by_email(email) do
          %User{} = existing -> {:ok, existing}
          nil -> Accounts.register_user(%{email: email})
        end

      case user do
        {:ok, user} ->
          # Confirm user if not yet confirmed so they can proceed
          unless user.confirmed_at do
            user
            |> User.confirm_changeset()
            |> WorthAsking.Repo.update()
          end

          conn
          |> put_session(:user_return_to, ~p"/contributors/apply")
          |> WorthAskingWeb.UserAuth.log_in_user(user, %{"remember_me" => "true"})

        {:error, changeset} ->
          render(conn, :new, changeset: changeset)
      end
    end
  end
end
