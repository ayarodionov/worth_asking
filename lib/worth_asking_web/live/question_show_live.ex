defmodule WorthAskingWeb.QuestionShowLive do
  use WorthAskingWeb, :live_view

  import WorthAskingWeb.Components.ResponseCard

  alias WorthAsking.Questions

  @max_perspectives 3
  @max_followups 3

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    user = socket.assigns.current_scope.user
    question = Questions.get_question_with_responses!(id)

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
      interactions = load_interactions(user.id, responses)

      {:ok,
       socket
       |> assign(:page_title, "Your Perspectives")
       |> assign(:question, question)
       |> assign(:responses, responses)
       |> assign(:interactions, interactions)
       |> assign(:total_expected, @max_perspectives)
       |> assign(:followup_text, "")
       |> assign(:followup_count, followup_count)
       |> assign(:max_followups, @max_followups)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto px-4 sm:px-6 py-8 sm:py-12">
      <a href={~p"/my-questions"} class="text-sm text-[#6F8F9D] hover:underline mb-8 inline-block">
        &larr; Dashboard
      </a>

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
      <div class="space-y-4 mb-12">
        <.response_card
          :for={{response, idx} <- Enum.with_index(@responses, 1)}
          response={response}
          index={idx}
          liked={interaction?(@interactions, response.id, "like")}
          saved={interaction?(@interactions, response.id, "save")}
        />

        <%!-- Placeholder cards --%>
        <.response_card_placeholder
          :for={idx <- (length(@responses) + 1)..@total_expected//1}
          :if={length(@responses) < @total_expected}
          index={idx}
        />
      </div>

      <%!-- Empty state --%>
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
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("send_followup", %{"text" => text}, socket) do
    text = String.trim(text)

    if text == "" do
      {:noreply, socket}
    else
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
  def handle_event("toggle_like", %{"response-id" => response_id}, socket) do
    user = socket.assigns.current_scope.user
    Questions.toggle_interaction(response_id, user.id, "like")
    {:noreply, refresh_interactions(socket)}
  end

  @impl true
  def handle_event("toggle_save", %{"response-id" => response_id}, socket) do
    user = socket.assigns.current_scope.user
    Questions.toggle_interaction(response_id, user.id, "save")
    {:noreply, refresh_interactions(socket)}
  end

  @impl true
  def handle_info({:new_response, _response}, socket) do
    user = socket.assigns.current_scope.user
    question = Questions.get_question_with_responses!(socket.assigns.question.id)
    responses = Enum.take(question.responses, @max_perspectives)
    interactions = load_interactions(user.id, responses)

    {:noreply,
     socket
     |> assign(:question, question)
     |> assign(:responses, responses)
     |> assign(:interactions, interactions)}
  end

  defp count_followups(_question), do: 0

  defp remaining_followups(count, max) do
    remaining = max - count
    if remaining == 1, do: "#{remaining} follow-up", else: "#{remaining} follow-ups"
  end

  defp load_interactions(_user_id, []), do: %{}
  defp load_interactions(user_id, responses) do
    response_ids = Enum.map(responses, & &1.id)
    Questions.list_interactions_for_user(user_id, response_ids)
  end

  defp interaction?(interactions, response_id, type) do
    interactions
    |> Map.get(response_id, [])
    |> Enum.any?(&(&1.type == type))
  end

  defp refresh_interactions(socket) do
    user = socket.assigns.current_scope.user
    interactions = load_interactions(user.id, socket.assigns.responses)
    assign(socket, :interactions, interactions)
  end
end
