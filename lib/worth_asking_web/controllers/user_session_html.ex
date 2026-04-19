defmodule WorthAskingWeb.UserSessionHTML do
  use WorthAskingWeb, :html

  embed_templates "user_session_html/*"

  defp local_mail_adapter? do
    Application.get_env(:worth_asking, WorthAsking.Mailer)[:adapter] == Swoosh.Adapters.Local
  end
end
