defmodule WorthAskingWeb.UserSessionController do
  use WorthAskingWeb, :controller

  alias WorthAsking.Accounts
  alias WorthAskingWeb.UserAuth

  def new(conn, _params) do
    email = get_in(conn.assigns, [:current_scope, Access.key(:user), Access.key(:email)])
    form = Phoenix.Component.to_form(%{"email" => email}, as: "user")

    render(conn, :new, form: form)
  end

  # magic link login
  def create(conn, %{"user" => %{"token" => token} = user_params} = params) do
    info =
      case params do
        %{"_action" => "confirmed"} -> "User confirmed successfully."
        _ -> "Welcome back!"
      end

    case Accounts.login_user_by_magic_link(token) do
      {:ok, {user, _expired_tokens}} ->
        conn
        |> put_flash(:info, info)
        |> UserAuth.log_in_user(user, user_params)

      {:error, :not_found} ->
        conn
        |> put_flash(:error, "The link is invalid or it has expired.")
        |> render(:new, form: Phoenix.Component.to_form(%{}, as: "user"))
    end
  end

  # email + password login
  def create(conn, %{"user" => %{"email" => email, "password" => password} = user_params}) do
    if user = Accounts.get_user_by_email_and_password(email, password) do
      conn
      |> put_flash(:info, "Welcome back!")
      |> UserAuth.log_in_user(user, user_params)
    else
      form = Phoenix.Component.to_form(user_params, as: "user")

      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      conn
      |> put_flash(:error, "Invalid email or password")
      |> render(:new, form: form)
    end
  end

  # magic link request
  def create(conn, %{"user" => %{"email" => email}}) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_login_instructions(
        user,
        &url(~p"/users/log-in/#{&1}")
      )
    end

    info =
      "If your email is in our system, you will receive instructions for logging in shortly."

    conn
    |> put_flash(:info, info)
    |> redirect(to: ~p"/users/log-in")
  end

  def confirm(conn, %{"token" => token}) do
    if user = Accounts.get_user_by_magic_link_token(token) do
      # Auto-login contributors who haven't completed onboarding
      if user.role == :contributor && !contributor_onboarded?(user) do
        case Accounts.login_user_by_magic_link(token) do
          {:ok, {user, _}} ->
            conn
            |> put_flash(:info, "Welcome to Worth Asking!")
            |> UserAuth.log_in_user(user, %{"remember_me" => "true"})

          {:error, :not_found} ->
            conn
            |> put_flash(:error, "The link is invalid or it has expired.")
            |> redirect(to: ~p"/users/log-in")
        end
      else
        form = Phoenix.Component.to_form(%{"token" => token}, as: "user")

        conn
        |> assign(:user, user)
        |> assign(:form, form)
        |> render(:confirm)
      end
    else
      conn
      |> put_flash(:error, "Magic link is invalid or it has expired.")
      |> redirect(to: ~p"/users/log-in")
    end
  end

  defp contributor_onboarded?(user) do
    case WorthAsking.Contributors.get_profile_by_user(user.id) do
      %{onboarding_completed: true} -> true
      _ -> false
    end
  end

  def setup_onboarding(conn, %{"token" => token}) do
    case Accounts.verify_onboarding_token(token) do
      {:ok, user} ->
        if user.role == :contributor do
          # Create session without server-side redirect.
          # Render a page that does client-side redirect so cookies are stored first.
          token = Accounts.generate_user_session_token(user)

          conn
          |> put_session(:user_token, token)
          |> put_session(:user_remember_me, true)
          |> put_resp_cookie("_worth_asking_web_user_remember_me", token,
            sign: true,
            max_age: 14 * 24 * 60 * 60,
            same_site: "Lax"
          )
          |> put_resp_content_type("text/html")
          |> send_resp(200, """
          <!DOCTYPE html>
          <html>
          <head>
            <meta http-equiv="refresh" content="0;url=/contributors/onboarding">
            <style>
              body { display: flex; align-items: center; justify-content: center; min-height: 100vh; font-family: Georgia, serif; background: #F7F7F5; color: #2F2F2F; }
            </style>
          </head>
          <body>
            <p>Welcome to Worth Asking — setting up your profile...</p>
            <script>window.location.href = "/contributors/onboarding";</script>
          </body>
          </html>
          """)
        else
          conn
          |> put_flash(:error, "Invalid onboarding link.")
          |> redirect(to: ~p"/")
        end

      {:error, _} ->
        conn
        |> put_flash(:error, "This onboarding link is invalid or has expired. Please contact support.")
        |> redirect(to: ~p"/users/log-in")
    end
  end

  @doc """
  Creates a session for a contributor using their onboarding token,
  then redirects to the guidelines or dashboard. No login page involved.
  """
  def activate_contributor(conn, %{"token" => token}) do
    case Accounts.verify_onboarding_token(token) do
      {:ok, user} ->
        if user.role == :contributor do
          conn
          |> put_session(:user_return_to, ~p"/contributors/guidelines")
          |> UserAuth.log_in_user(user, %{"remember_me" => "true"})
        else
          conn
          |> put_flash(:error, "Invalid activation link.")
          |> redirect(to: ~p"/")
        end

      {:error, _} ->
        conn
        |> put_flash(:error, "This link is invalid or has expired. Please contact support.")
        |> redirect(to: ~p"/users/log-in")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> UserAuth.log_out_user()
  end
end
