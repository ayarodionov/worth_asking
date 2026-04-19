defmodule WorthAsking.Accounts.UserNotifier do
  import Swoosh.Email

  alias WorthAsking.Mailer
  alias WorthAsking.Accounts.User

  # Delivers the email using the application mailer.
  defp deliver(recipient, subject, body) do
    email =
      new()
      |> to(recipient)
      |> from({"Worth Asking", System.get_env("MAIL_FROM", "onboarding@resend.dev")})
      |> subject(subject)
      |> text_body(body)

    case Mailer.deliver(email) do
      {:ok, _metadata} ->
        {:ok, email}

      {:error, reason} ->
        require Logger
        Logger.error("Failed to deliver email to #{recipient}: #{inspect(reason)}")
        {:error, reason}
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
  Notify a contributor that their application was approved, with onboarding link.
  """
  def deliver_approval_notification(user, onboarding_url) do
    first_name = user.first_name || user.email

    deliver(user.email, "You're invited to join Worth Asking as a Contributor", """
    Hi #{first_name},

    We reviewed your application and would like to invite you to join Worth Asking as a Contributor.

    Worth Asking connects men with real, thoughtful perspectives from women — without social pressure, awkwardness, or personal consequences. Your role is to offer clear, honest insight based on your experience and judgment.


    NEXT STEP — SET UP YOUR PROFILE

    To begin, please complete your onboarding here:

    #{onboarding_url}

    You'll be asked to:

      - Enter your phone number to receive text alerts when questions are sent to you
      - Add your payment details for weekly payouts
      - Confirm your availability and participation preferences


    HOW IT WORKS

    When a question is routed to you, you'll receive a text notification. You can choose to respond or ignore — there's no obligation to answer every question.

    Contributors are paid for accepted responses. Payments are issued weekly.


    GUIDELINES FOR RESPONSES

    We're not looking for perfection — we're looking for clarity and honesty.

      - Be direct, but not harsh
      - Be helpful, not performative
      - Answer as if you're speaking to someone who genuinely wants to understand
      - Avoid over-explaining or "teaching a lesson" — keep it grounded and real
      - Speak from your perspective, not as a universal authority


    SAFETY + BOUNDARIES

    We've built safeguards to protect both contributors and users:

      - You remain anonymous at all times
      - No direct messaging or ongoing conversations
      - Questions are screened before being sent out
      - You can skip any question, for any reason
      - Content moderation is in place to filter inappropriate or unsafe submissions

    This is not therapy, coaching, or emotional labor. It's perspective — offered cleanly, and without obligation.

    If you have any questions before getting started, you can reply directly to this email.

    We're glad to have you.

    — Worth Asking
    """)
  end
end
