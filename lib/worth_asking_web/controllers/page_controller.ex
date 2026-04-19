defmodule WorthAskingWeb.PageController do
  use WorthAskingWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
