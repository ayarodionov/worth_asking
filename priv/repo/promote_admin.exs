email = System.get_env("ADMIN_EMAIL") || "ayarodionov@yahoo.com"

user = WorthAsking.Repo.get_by(WorthAsking.Accounts.User, email: email)

if user do
  user
  |> Ecto.Changeset.change(role: :admin)
  |> WorthAsking.Repo.update!()

  IO.puts("Promoted #{user.email} to admin")
else
  IO.puts("User with email #{email} not found")
end
