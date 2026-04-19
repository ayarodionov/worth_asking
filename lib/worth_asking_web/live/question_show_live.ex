defmodule WorthAskingWeb.QuestionShowLive do
  use WorthAskingWeb, :live_view

  alias WorthAsking.Questions

  @max_perspectives 3
  @max_followups 3

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    question = Questions.get_question_with_responses!(id)
    user = socket.assigns.current_scope.user

    if question.user_id != user.id do
      {:ok,
       socket
       |> put_flash(:error, "You can only view your own questions.")
       |> redirect(to: ~p"/my-questions")}
    else
      if connected?(socket) do
        Phoenix.PubSub.subscribe(WorthAsking.PubSub, "question:#{question.id}")
      end

      responses = Enum.take(question.responses, @max_perspectives)
      followup_count = count_followups(question)

      {:ok,
       socket
       |> assign(:page_title, "Your Perspectives")
       |> assign(:question, question)
       |> assign(:responses, responses)
       |> assign(:total_expected, @max_perspectives)
       |> assign(:followup_text, "")
       |> assign(:followup_count, followup_count)
       |> assign(:max_followups, @max_followups)
       |> assign(:marked_helpful, false)
       |> assign(:saved, false)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto px-6 py-12">
      <%!-- Back link --%>
      <a href={~p"/my-questions"} class="text-sm text-[#6F8F9D] hover:underline mb-8 inline-block">
        &larr; My questions
      </a>

      <%!-- Header --%>
      <div class="mb-8">
        <h1 class="text-2xl font-semibold text-[#2F2F2F] mb-1" style="font-family: Georgia, serif;">
          Your perspectives
        </h1>
        <p class="text-sm text-[#2F2F2F]/50">
          Three responses to your question
        </p>
      </div>

      <%!-- Original question --%>
      <div class="mb-10 pb-8 border-b border-[#E4E6E3]">
        <p class="text-xs text-[#2F2F2F]/40 uppercase tracking-wider mb-3">Your question</p>
        <p class="text-lg text-[#2F2F2F] leading-relaxed" style="font-family: Georgia, serif;">
          "{@question.text}"
        </p>
        <div :if={@question.image_paths != []} class="flex gap-3 mt-4">
          <img
            :for={path <- @question.image_paths}
            src={path}
            class="w-20 h-20 object-cover rounded-lg border border-[#E4E6E3]"
          />
        </div>
      </div>

      <%!-- Loading state --%>
      <%= if length(@responses) < @total_expected do %>
        <div class="mb-6">
          <div class="flex items-center gap-3 text-sm text-[#2F2F2F]/50">
            <div class="w-4 h-4 border-2 border-[#A8BDA4] border-t-transparent rounded-full animate-spin"></div>
            <span>{length(@responses)} of {@total_expected} perspectives ready</span>
          </div>
        </div>
      <% end %>

      <%!-- Response cards --%>
      <div class="space-y-6 mb-12">
        <div
          :for={{response, idx} <- Enum.with_index(@responses, 1)}
          class="bg-white border border-[#E4E6E3] rounded-lg p-6"
        >
          <p class="text-xs font-medium text-[#2F2F2F]/40 uppercase tracking-wider mb-4">
            Perspective {idx}
          </p>
          <p class="text-sm text-[#2F2F2F]/80 leading-relaxed whitespace-pre-line">
            {response.text}
          </p>
        </div>

        <%!-- Placeholder cards for missing perspectives --%>
        <div
          :for={idx <- (length(@responses) + 1)..@total_expected//1}
          :if={length(@responses) < @total_expected}
          class="border border-dashed border-[#E4E6E3] rounded-lg p-6"
        >
          <p class="text-xs font-medium text-[#2F2F2F]/20 uppercase tracking-wider mb-4">
            Perspective {idx}
          </p>
          <div class="flex items-center gap-2 text-sm text-[#2F2F2F]/30">
            <div class="w-3 h-3 border-2 border-[#E4E6E3] border-t-transparent rounded-full animate-spin"></div>
            <span>Waiting for response...</span>
          </div>
        </div>
      </div>

      <%!-- Empty state (no responses at all) --%>
      <%= if @responses == [] and length(@question.responses) == 0 do %>
        <div class="text-center py-12 bg-white border border-[#E4E6E3] rounded-lg mb-12">
          <p class="text-[#2F2F2F]/50 mb-1">Your question is out there.</p>
          <p class="text-sm text-[#2F2F2F]/40">Perspectives are on their way. Check back soon.</p>
        </div>
      <% end %>

      <%!-- Follow-up section --%>
      <%= if @followup_count < @max_followups do %>
        <div class="mb-12 pb-8 border-b border-[#E4E6E3]">
          <p class="text-sm font-medium text-[#2F2F2F] mb-3">Add more context or ask a follow-up</p>
          <.form for={%{}} phx-submit="send_followup" class="flex gap-3">
            <input
              type="text"
              name="text"
              value={@followup_text}
              placeholder="e.g. What if we've only been on two dates?"
              class="flex-1 border border-[#E4E6E3] rounded-lg px-4 py-2.5 text-sm focus:outline-none focus:border-[#6F8F9D] focus:ring-1 focus:ring-[#6F8F9D] bg-white"
            />
            <button
              type="submit"
              class="bg-[#6F8F9D] text-white px-5 py-2.5 rounded-lg text-sm font-medium hover:bg-[#5a7a87] transition-colors"
            >
              Send
            </button>
          </.form>
          <p class="text-xs text-[#2F2F2F]/30 mt-2">
            {remaining_followups(@followup_count, @max_followups)} remaining
          </p>
        </div>
      <% end %>

      <%!-- Actions --%>
      <div class="flex flex-wrap items-center gap-3">
        <a
          href={~p"/questions/new"}
          class="bg-[#6F8F9D] text-white px-5 py-2.5 rounded-lg text-sm font-medium hover:bg-[#5a7a87] transition-colors"
        >
          Ask another question
        </a>
        <button
          :if={not @saved}
          phx-click="save"
          class="border border-[#E4E6E3] text-[#2F2F2F]/70 px-5 py-2.5 rounded-lg text-sm font-medium hover:border-[#6F8F9D] transition-colors"
        >
          Save this
        </button>
        <span :if={@saved} class="text-sm text-[#A8BDA4]">
          Saved
        </span>
        <button
          :if={not @marked_helpful}
          phx-click="mark_helpful"
          class="border border-[#E4E6E3] text-[#2F2F2F]/70 px-5 py-2.5 rounded-lg text-sm font-medium hover:border-[#A8BDA4] transition-colors"
        >
          Mark helpful
        </button>
        <span :if={@marked_helpful} class="text-sm text-[#A8BDA4]">
          Marked as helpful
        </span>
      </div>
    </div>
    """
  end

  # --- Events ---

  @impl true
  def handle_event("send_followup", %{"text" => text}, socket) do
    text = String.trim(text)

    if text == "" do
      {:noreply, socket}
    else
      # For MVP, follow-ups create a new question linked to the original
      user = socket.assigns.current_scope.user
      original = socket.assigns.question

      attrs = %{
        "text" => text,
        "category" => to_string(original.category),
        "image_paths" => []
      }

      case Questions.create_question(user, attrs) do
        {:ok, _followup} ->
          {:noreply,
           socket
           |> assign(:followup_text, "")
           |> update(:followup_count, &(&1 + 1))
           |> put_flash(:info, "Follow-up sent. You'll get new perspectives soon.")}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Could not send follow-up. Try again.")}
      end
    end
  end

  @impl true
  def handle_event("save", _params, socket) do
    {:noreply, assign(socket, :saved, true)}
  end

  @impl true
  def handle_event("mark_helpful", _params, socket) do
    {:noreply, assign(socket, :marked_helpful, true)}
  end

  # --- PubSub ---

  @impl true
  def handle_info({:new_response, _response}, socket) do
    question = Questions.get_question_with_responses!(socket.assigns.question.id)
    responses = Enum.take(question.responses, @max_perspectives)

    {:noreply,
     socket
     |> assign(:question, question)
     |> assign(:responses, responses)}
  end

  # --- Helpers ---

  defp count_followups(_question), do: 0

  defp remaining_followups(count, max) do
    remaining = max - count
    if remaining == 1, do: "#{remaining} follow-up", else: "#{remaining} follow-ups"
  end
end
