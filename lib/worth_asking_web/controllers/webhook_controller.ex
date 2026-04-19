defmodule WorthAskingWeb.WebhookController do
  use WorthAskingWeb, :controller

  # TODO: Verify Stripe signature and handle events

  def stripe(conn, _params) do
    {:ok, _body, conn} = Plug.Conn.read_body(conn)

    conn
    |> put_status(200)
    |> json(%{status: "ok"})
  end
end
