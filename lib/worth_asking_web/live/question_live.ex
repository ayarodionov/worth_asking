defmodule WorthAskingWeb.QuestionLive do
  use WorthAskingWeb, :live_view

  alias WorthAsking.Questions
  alias WorthAsking.Categories

  @price_cents 499

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user

    if Questions.has_active_question?(user.id) do
      {:ok,
       socket
       |> put_flash(:info, "You already have an active question. Wait for responses before asking another.")
       |> redirect(to: ~p"/my-questions")}
    else
      {:ok,
       socket
       |> assign(:page_title, "Ask a Question")
       |> assign(:step, :question)
       |> assign(:question_text, "")
       |> assign(:category, nil)
       |> assign(:char_count, 0)
       |> assign(:price_cents, @price_cents)
       |> assign(:categories, Categories.all())
       |> assign(:error, nil)}
    end
  end

  @impl true
  def handle_params(params, _uri, socket) do
    case params do
      %{"q" => q} when q != "" ->
        text = String.trim(q)

        {:noreply,
         socket
         |> assign(:question_text, text)
         |> assign(:char_count, String.length(text))}

      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-xl mx-auto px-4 sm:px-6 py-8 sm:py-12">
      <%!-- Progress indicator --%>
      <div class="flex items-center justify-center gap-2 mb-8">
        <div :for={s <- [:question, :category, :review, :confirmed]} class={[
          "w-2 h-2 rounded-full transition-colors",
          if(s == @step, do: "bg-[#2F2F2F]", else: step_complete?(s, @step) && "bg-[#A8BDA4]" || "bg-[#2F2F2F]/15")
        ]} />
      </div>

      <%!-- STEP 1: Question Entry --%>
      <%= if @step == :question do %>
        <div class="mb-8">
          <h1 class="text-2xl font-semibold mb-2" style="font-family: Georgia, serif;">
            Ask your question
          </h1>
          <p class="text-sm text-[#2F2F2F]/50">
            This is anonymous. Contributors will not see your name, email, or personal account details.
          </p>
        </div>

        <div class="space-y-4">
          <div>
            <textarea
              name="text"
              rows="6"
              phx-keyup="update_text"
              placeholder="What do you want a woman's honest perspective on?"
              class="w-full border border-[#E4E6E3] rounded-lg p-4 text-base resize-none focus:outline-none focus:border-[#6F8F9D] focus:ring-1 focus:ring-[#6F8F9D] bg-white leading-relaxed"
            >{@question_text}</textarea>
            <p class={[
              "text-xs mt-2",
              if(@char_count < 20, do: "text-[#2F2F2F]/40", else: "text-[#6F8F6B]")
            ]}>
              <%= if @char_count > 0 and @char_count < 20 do %>
                Please enter a little more detail so contributors can give you a useful answer.
              <% else %>
                {@char_count} characters
                <%= if @char_count < 20 do %>
                  <span class="text-[#2F2F2F]/30">(minimum 20)</span>
                <% end %>
              <% end %>
            </p>
          </div>

          <button
            phx-click="to_category"
            disabled={@char_count < 20}
            class={[
              "w-full py-3 rounded-lg text-sm font-medium transition-colors",
              if(@char_count >= 20,
                do: "bg-[#6F8F9D] text-white hover:bg-[#5a7a87]",
                else: "bg-[#E4E6E3] text-[#2F2F2F]/40 cursor-not-allowed"
              )
            ]}
          >
            Continue
          </button>
        </div>
      <% end %>

      <%!-- STEP 2: Category Selection --%>
      <%= if @step == :category do %>
        <div class="mb-8">
          <h1 class="text-2xl font-semibold mb-2" style="font-family: Georgia, serif;">
            Choose a Category
          </h1>
          <p class="text-sm text-[#2F2F2F]/50">
            This helps us send your question to the right contributors.
          </p>
        </div>

        <div class="grid grid-cols-1 sm:grid-cols-2 gap-3 mb-6">
          <button
            :for={cat <- @categories}
            phx-click="select_category"
            phx-value-category={cat.id}
            class={[
              "border rounded-lg p-4 text-left transition-colors",
              if(@category == cat.id,
                do: "border-[#6F8F9D] bg-[#6F8F9D]/5",
                else: "border-[#E4E6E3] hover:border-[#A8BDA4] bg-white"
              )
            ]}
          >
            <span class="text-sm font-medium block">{cat.label}</span>
            <span class="text-xs text-[#2F2F2F]/40 mt-0.5 block">{cat.description}</span>
          </button>
        </div>

        <div class="flex gap-3">
          <button
            phx-click="back_to_question"
            class="px-5 py-3 rounded-lg text-sm font-medium text-[#2F2F2F]/50 hover:text-[#2F2F2F]/70 transition-colors"
          >
            Back
          </button>
          <button
            phx-click="to_review"
            disabled={@category == nil}
            class={[
              "flex-1 py-3 rounded-lg text-sm font-medium transition-colors",
              if(@category,
                do: "bg-[#6F8F9D] text-white hover:bg-[#5a7a87]",
                else: "bg-[#E4E6E3] text-[#2F2F2F]/40 cursor-not-allowed"
              )
            ]}
          >
            Continue
          </button>
        </div>
      <% end %>

      <%!-- STEP 3: Review + Payment --%>
      <%= if @step == :review do %>
        <div class="mb-8">
          <h1 class="text-2xl font-semibold mb-2" style="font-family: Georgia, serif;">
            Review Your Question
          </h1>
        </div>

        <%!-- Question preview --%>
        <div class="bg-white border border-[#E4E6E3] rounded-lg p-5 sm:p-6 mb-6">
          <p class="text-xs text-[#2F2F2F]/40 uppercase tracking-wider mb-3">Your question</p>
          <p class="text-base text-[#2F2F2F] leading-relaxed mb-4" style="font-family: Georgia, serif;">
            "{@question_text}"
          </p>
          <span class="text-xs font-medium px-2 py-1 rounded-full bg-[#A8BDA4]/20 text-[#6F8F6B]">
            {Categories.label(@category)}
          </span>
        </div>

        <%!-- What happens next --%>
        <div class="bg-[#F7F7F5] border border-[#E4E6E3] rounded-lg p-5 mb-6">
          <p class="text-xs text-[#2F2F2F]/40 uppercase tracking-wider mb-3">What happens next</p>
          <ul class="space-y-2 text-sm text-[#2F2F2F]/60">
            <li>Your question will be sent anonymously to contributors in this category.</li>
            <li>You'll receive up to 3 thoughtful responses.</li>
            <li>This is a one-time submission.</li>
          </ul>
        </div>

        <%!-- Payment --%>
        <div class="bg-white border border-[#E4E6E3] rounded-lg p-5 sm:p-6 mb-6">
          <div class="flex items-center justify-between mb-4">
            <p class="text-sm font-medium text-[#2F2F2F]">One question, 3 perspectives</p>
            <p class="text-lg font-semibold text-[#2F2F2F]">{format_price(@price_cents)}</p>
          </div>
          <p class="text-xs text-[#2F2F2F]/40">
            Secure payment. Your question is only sent after payment is complete.
          </p>
        </div>

        <%= if @error do %>
          <div class="bg-red-50 border border-red-200 text-red-700 text-sm rounded-lg p-4 mb-4">
            {@error}
          </div>
        <% end %>

        <div class="flex gap-3">
          <button
            phx-click="back_to_category"
            class="px-5 py-3 rounded-lg text-sm font-medium text-[#2F2F2F]/50 hover:text-[#2F2F2F]/70 transition-colors"
          >
            Back
          </button>
          <button
            phx-click="pay_and_submit"
            class="flex-1 py-3 rounded-lg text-sm font-medium bg-[#6F8F9D] text-white hover:bg-[#5a7a87] transition-colors"
          >
            Pay & Submit Question
          </button>
        </div>
      <% end %>

      <%!-- STEP 4: Confirmation --%>
      <%= if @step == :confirmed do %>
        <div class="text-center py-12">
          <div class="w-14 h-14 rounded-full bg-[#A8BDA4]/20 flex items-center justify-center mx-auto mb-6">
            <span class="text-[#6F8F6B] text-2xl">&#10003;</span>
          </div>
          <h1 class="text-2xl font-semibold mb-3" style="font-family: Georgia, serif;">
            Your question has been submitted.
          </h1>
          <p class="text-sm text-[#2F2F2F]/50 max-w-sm mx-auto mb-8">
            We'll send it to matching contributors and notify you when responses are ready.
          </p>

          <div class="bg-[#F7F7F5] border border-[#E4E6E3] rounded-lg p-6 max-w-sm mx-auto mb-8 text-left">
            <p class="text-xs text-[#2F2F2F]/40 uppercase tracking-wider mb-3">What happens next</p>
            <ol class="space-y-2 text-sm text-[#2F2F2F]/60">
              <li class="flex gap-2">
                <span class="text-[#6F8F9D] font-medium">1.</span>
                Your question is reviewed and matched.
              </li>
              <li class="flex gap-2">
                <span class="text-[#6F8F9D] font-medium">2.</span>
                Contributors who fit the topic may respond.
              </li>
              <li class="flex gap-2">
                <span class="text-[#6F8F9D] font-medium">3.</span>
                You'll be notified when responses are available.
              </li>
            </ol>
          </div>

          <div class="space-y-3">
            <a
              href={~p"/my-questions"}
              class="block bg-[#6F8F9D] text-white px-6 py-3 rounded-lg text-sm font-medium hover:bg-[#5a7a87] transition-colors"
            >
              Go to My Questions
            </a>
            <a
              href={~p"/questions/new"}
              class="block text-[#6F8F9D] text-sm hover:underline"
            >
              Ask another question
            </a>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  # --- Events ---

  @impl true
  def handle_event("update_text", %{"value" => text}, socket) do
    {:noreply,
     socket
     |> assign(:question_text, text)
     |> assign(:char_count, String.length(String.trim(text)))}
  end

  @impl true
  def handle_event("to_category", _params, socket) do
    if socket.assigns.char_count >= 20 do
      {:noreply, assign(socket, :step, :category)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("select_category", %{"category" => category}, socket) do
    {:noreply, assign(socket, :category, String.to_existing_atom(category))}
  end

  @impl true
  def handle_event("to_review", _params, socket) do
    if socket.assigns.category do
      {:noreply, assign(socket, :step, :review)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("back_to_question", _params, socket) do
    {:noreply, assign(socket, :step, :question)}
  end

  @impl true
  def handle_event("back_to_category", _params, socket) do
    {:noreply, assign(socket, :step, :category)}
  end

  @impl true
  def handle_event("pay_and_submit", _params, socket) do
    user = socket.assigns.current_scope.user

    if Questions.has_active_question?(user.id) do
      {:noreply,
       socket
       |> put_flash(:error, "You already have an active question.")
       |> redirect(to: ~p"/my-questions")}
    else
      attrs = %{
        "text" => String.trim(socket.assigns.question_text),
        "category" => to_string(socket.assigns.category),
        "image_paths" => []
      }

      case Questions.create_question(user, attrs) do
        {:ok, question} ->
          # Demo payment: auto-complete
          case Questions.create_payment(question, user, @price_cents) do
            {:ok, payment} ->
              payment
              |> Ecto.Changeset.change(status: :completed)
              |> WorthAsking.Repo.update()

              Questions.update_question_status(question, :paid)

            _ ->
              :ok
          end

          {:noreply, assign(socket, :step, :confirmed)}

        {:error, _changeset} ->
          {:noreply, assign(socket, :error, "Could not submit your question. Please try again.")}
      end
    end
  end

  # --- Helpers ---

  defp format_price(cents) do
    dollars = div(cents, 100)
    remainder = rem(cents, 100)
    "$#{dollars}.#{String.pad_leading(Integer.to_string(remainder), 2, "0")}"
  end

  defp step_complete?(check_step, current_step) do
    order = %{question: 0, category: 1, review: 2, confirmed: 3}
    Map.get(order, check_step, 0) < Map.get(order, current_step, 0)
  end
end
