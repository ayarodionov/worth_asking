defmodule WorthAsking.Accounts.UserNotifier do
  import Swoosh.Email

  alias WorthAsking.Mailer
  alias WorthAsking.Accounts.User

  # Delivers the email using the application mailer.
  defp deliver(recipient, subject, body) do
    email =
      new()
      |> to(recipient)
      |> from({"WorthAsking", "contact@example.com"})
      |> subject(subject)
      |> text_body(body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  @doc """
  Deliver instructions to update a user email.
  """
  def deliver_update_email_instructions(user, url) do
    deliver(user.email, "Update email instructions", """

    ==============================

    Hi #{user.email},

    You can change your email by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to log in with a magic link.
  """
  def deliver_login_instructions(user, url) do
    case user do
      %User{confirmed_at: nil} -> deliver_confirmation_instructions(user, url)
      _ -> deliver_magic_link_instructions(user, url)
    end
  end

  defp deliver_magic_link_instructions(user, url) do
    deliver(user.email, "Log in instructions", """

    ==============================

    Hi #{user.email},

    You can log into your account by visiting the URL below:

    #{url}

    If you didn't request this email, please ignore this.

    ==============================
    """)
  end

  defp deliver_confirmation_instructions(user, url) do
    deliver(user.email, "Confirmation instructions", """

    ==============================

    Hi #{user.email},

    You can confirm your account by visiting the URL below:

    #{url}

    If you didn't create an account with us, please ignore this.

    ==============================
    """)
  end

  @doc """
  Notify a contributor that a new question is available.
  """
  def deliver_question_notification(user, question) do
    category_label =
      question.category
      |> to_string()
      |> String.replace("_", " ")
      |> String.split(" ")
      |> Enum.map(&String.capitalize/1)
      |> Enum.join(" ")

    session_label = String.capitalize(question.session_type || "basic")

    deliver(user.email, "New question waiting for your perspective", """

    ==============================

    Hi,

    A new #{category_label} question is waiting for your perspective.

    Session type: #{session_label}

    Log in to your dashboard to respond:
    https://worthasking.com/dashboard

    ==============================
    """)
  end

  @doc """
  Notify a contributor that their application was approved.
  """
  def deliver_approval_notification(user) do
    deliver(user.email, "You've been approved as a Worth Asking advisor", """

    ==============================

    Congratulations!

    Your application to become a Worth Asking advisor has been approved.

    You can now log in to your dashboard and start responding to questions:
    https://worthasking.com/dashboard

    Remember to set your availability so you can receive notifications
    when new questions come in.

    ==============================
    """)
  end
end
