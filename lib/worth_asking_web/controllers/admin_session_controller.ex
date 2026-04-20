defmodule WorthAskingWeb.AdminSessionController do
  use WorthAskingWeb, :controller

  alias WorthAsking.Admin
  alias WorthAskingWeb.AdminAuth

  def new(conn, _params) do
    conn
    |> assign(:admin_login_page, true)
    |> render(:new, error: nil)
  end

  def create(conn, %{"admin" => %{"email" => email, "password" => password}}) do
    if admin = Admin.get_admin_by_email_and_password(email, password) do
      AdminAuth.log_in_admin(conn, admin)
    else
      conn
      |> assign(:admin_login_page, true)
      |> render(:new, error: "Invalid email or password")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> AdminAuth.log_out_admin()
  end
end
