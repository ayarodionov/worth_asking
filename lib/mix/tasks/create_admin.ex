defmodule Mix.Tasks.CreateAdmin do
  @moduledoc """
  Creates an admin account.

  Usage:
    mix create_admin email@example.com yourpassword
  """

  use Mix.Task

  @shortdoc "Create an admin account"

  @impl Mix.Task
  def run([email, password]) do
    Mix.Task.run("app.start")

    case WorthAsking.Admin.create_admin(%{email: email, password: password}) do
      {:ok, admin} ->
        Mix.shell().info("Admin created: #{admin.email}")

      {:error, changeset} ->
        errors =
          Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
            Enum.reduce(opts, msg, fn {key, value}, acc ->
              String.replace(acc, "%{#{key}}", to_string(value))
            end)
          end)

        Mix.shell().error("Failed to create admin: #{inspect(errors)}")
    end
  end

  def run(_) do
    Mix.shell().error("Usage: mix create_admin <email> <password>")
  end
end
