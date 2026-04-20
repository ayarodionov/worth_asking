defmodule WorthAskingWeb.AdminAuth do
  @moduledoc """
  Admin authentication — completely separate from user auth.
  Uses its own session key, cookie, and token table.
  """

  use WorthAskingWeb, :verified_routes

  import Plug.Conn
  import Phoenix.Controller

  alias WorthAsking.Admin

  @admin_cookie "_worth_asking_admin_remember_me"
  @max_cookie_age_in_days 7
  @admin_cookie_options [
    sign: true,
    max_age: @max_cookie_age_in_days * 24 * 60 * 60,
    same_site: "Lax"
  ]

  def log_in_admin(conn, admin) do
    token = Admin.generate_admin_session_token(admin)

    conn
    |> renew_session()
    |> put_session(:admin_token, token)
    |> put_resp_cookie(@admin_cookie, token, @admin_cookie_options)
    |> redirect(to: ~p"/admin")
  end

  def log_out_admin(conn) do
    admin_token = get_session(conn, :admin_token)
    admin_token && Admin.delete_admin_session_token(admin_token)

    conn
    |> renew_session()
    |> delete_resp_cookie(@admin_cookie, @admin_cookie_options)
    |> redirect(to: ~p"/admin/login")
  end

  defp renew_session(conn) do
    delete_csrf_token()

    conn
    |> configure_session(renew: true)
    |> clear_session()
  end

  # --- Plugs ---

  def fetch_current_admin(conn, _opts) do
    conn = assign(conn, :current_scope, nil)

    with token when is_binary(token) <- get_admin_token(conn),
         admin when not is_nil(admin) <- Admin.get_admin_by_session_token(token) do
      assign(conn, :current_admin, admin)
    else
      _ -> assign(conn, :current_admin, nil)
    end
  end

  defp get_admin_token(conn) do
    if token = get_session(conn, :admin_token) do
      token
    else
      conn = fetch_cookies(conn, signed: [@admin_cookie])
      conn.cookies[@admin_cookie]
    end
  end

  def require_admin(conn, _opts) do
    if conn.assigns[:current_admin] do
      conn
    else
      conn
      |> put_flash(:error, "You must log in to access the admin area.")
      |> redirect(to: ~p"/admin/login")
      |> halt()
    end
  end

  def redirect_if_admin_authenticated(conn, _opts) do
    if conn.assigns[:current_admin] do
      conn
      |> redirect(to: ~p"/admin")
      |> halt()
    else
      conn
    end
  end

  def live_session_data(conn) do
    %{"admin_token" => get_session(conn, :admin_token)}
  end

  # --- LiveView on_mount ---

  def on_mount(:require_admin, _params, session, socket) do
    admin = get_admin_from_session(session)

    if admin do
      {:cont, Phoenix.Component.assign(socket, :current_admin, admin)}
    else
      socket =
        socket
        |> Phoenix.LiveView.put_flash(:error, "You must log in to access the admin area.")
        |> Phoenix.LiveView.redirect(to: ~p"/admin/login")

      {:halt, socket}
    end
  end

  defp get_admin_from_session(session) do
    if token = session["admin_token"] do
      Admin.get_admin_by_session_token(token)
    end
  end
end
