defmodule WorthAskingWeb.StripeController do
  use WorthAskingWeb, :controller

  alias WorthAsking.Questions

  def create_checkout(conn, %{"question_id" => question_id}) do
    user = conn.assigns.current_user
    question = Questions.get_question!(question_id)

    # Demo mode: create a completed payment and mark question as paid
    case Questions.create_payment(question, user, 499) do
      {:ok, payment} ->
        payment
        |> Ecto.Changeset.change(status: :completed)
        |> WorthAsking.Repo.update()

        Questions.update_question_status(question, :paid)

        conn
        |> put_flash(:info, "Responses unlocked!")
        |> redirect(to: ~p"/questions/#{question_id}")

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Payment failed. Please try again.")
        |> redirect(to: ~p"/questions/#{question_id}")
    end
  end

  def connect_onboarding(conn, _params) do
    conn
    |> put_flash(:info, "Stripe Connect coming soon")
    |> redirect(to: ~p"/")
  end

  def connect_return(conn, _params) do
    conn
    |> put_flash(:info, "Stripe account connected")
    |> redirect(to: ~p"/dashboard")
  end
end
