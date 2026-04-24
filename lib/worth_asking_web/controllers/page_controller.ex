defmodule WorthAskingWeb.PageController do
  use WorthAskingWeb, :controller

  alias WorthAsking.Accounts
  alias WorthAsking.Accounts.User
  alias WorthAskingWeb.UserAuth

  def home(conn, _params) do
    render(conn, :home)
  end

  def ask(conn, params) do
    q = params |> Map.get("q", "") |> String.trim()

    if q == "" do
      conn
      |> put_flash(:error, "Please enter a question first.")
      |> redirect(to: ~p"/")
    else
      if conn.assigns.current_scope && conn.assigns.current_scope.user do
        redirect(conn, to: "/questions/new?" <> URI.encode_query(%{"q" => q}))
      else
        conn
        |> put_session(:user_return_to, "/questions/new?" <> URI.encode_query(%{"q" => q}))
        |> render(:ask, question: q, email: "", errors: [])
      end
    end
  end

  def create_and_ask(conn, %{"ask" => ask_params}) do
    email = ask_params["email"] || ""
    password = ask_params["password"] || ""
    question = ask_params["question"] || ""

    result =
      WorthAsking.Repo.transaction(fn ->
        with {:ok, user} <- Accounts.register_user(%{"email" => email}),
             {:ok, user} <- set_password(user, password) do
          user
        else
          {:error, changeset} -> WorthAsking.Repo.rollback(changeset)
        end
      end)

    case result do
      {:ok, user} ->
        return_path = "/questions/new?" <> URI.encode_query(%{"q" => question})

        conn
        |> put_session(:user_return_to, return_path)
        |> UserAuth.log_in_user(user, %{"remember_me" => "true"})

      {:error, %Ecto.Changeset{} = changeset} ->
        errors =
          Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
            Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
              opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
            end)
          end)
          |> Enum.flat_map(fn {field, msgs} ->
            Enum.map(msgs, &"#{Phoenix.Naming.humanize(field)} #{&1}")
          end)

        render(conn, :ask, question: question, email: email, errors: errors)
    end
  end

  defp set_password(user, password) do
    user
    |> User.password_changeset(%{password: password})
    |> WorthAsking.Repo.update()
  end
end
