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

  def create(conn, %{"user" => user_params}) do
    email = user_params["email"]
    phone = user_params["phone"]

    # If already logged in, skip straight to the application
    if conn.assigns.current_scope && conn.assigns.current_scope.user do
      conn
      |> redirect(to: ~p"/contributors/apply")
    else
      case Accounts.get_user_by_email(email) do
        %User{} = user ->
          # Existing user — update phone if provided, send magic link
          if phone && phone != "" do
            Accounts.update_user_phone(user, phone)
          end

          Accounts.deliver_login_instructions(
            user,
            &url(~p"/users/log-in/#{&1}")
          )

          conn
          |> put_session(:user_return_to, ~p"/contributors/apply")
          |> put_flash(:info, "You already have an account! Check your email for a login link — it will take you straight to the advisor application.")
          |> redirect(to: ~p"/advisors/join")

        nil ->
          # New user — register with phone and send magic link
          case Accounts.register_user(%{email: email, phone: phone}) do
            {:ok, user} ->
              Accounts.deliver_login_instructions(
                user,
                &url(~p"/users/log-in/#{&1}")
              )

              conn
              |> put_session(:user_return_to, ~p"/contributors/apply")
              |> put_flash(:info, "Check your email! Click the link to verify your account and start your advisor application.")
              |> redirect(to: ~p"/advisors/join")

            {:error, changeset} ->
              render(conn, :new, changeset: changeset)
          end
      end
    end
  end
end
