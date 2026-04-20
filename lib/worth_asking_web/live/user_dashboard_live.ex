defmodule WorthAskingWeb.UserDashboardLive do
  use WorthAskingWeb, :live_view

  import WorthAskingWeb.Components.ResponseCard

  alias WorthAsking.Questions
  alias WorthAsking.Categories

  @max_perspectives 3
  @max_followups 3

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    questions = Questions.list_questions_for_user(user.id)

    if connected?(socket) do
      Phoenix.PubSub.subscribe(WorthAsking.PubSub, "user:#{user.id}")

      Enum.each(questions, fn q ->
        Phoenix.PubSub.subscribe(WorthAsking.PubSub, "question:#{q.id}")
      end)
    end

    {active, history} = split_questions(questions)
    active_question = load_active_question(active)
    responses = get_responses(active_question)
    interactions = load_interactions(user.id, responses)

    {:ok,
     socket
     |> assign(:page_title, "Dashboard")
     |> assign(:tab, :active)
     |> assign(:questions, questions)
     |> assign(:active_questions, active)
     |> assign(:history_questions, history)
     |> assign(:active_question, active_question)
     |> assign(:responses, responses)
     |> assign(:interactions, interactions)
     |> assign(:total_expected, @max_perspectives)
     |> assign(:followup_text, "")
     |> assign(:followup_count, 0)
     |> assign(:max_followups, @max_followups)
     |> assign(:expanded_history, MapSet.new())
     |> assign(:history_data, %{})}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto px-4 sm:px-6 py-8 sm:py-12">
      <%!-- Tab navigation --%>
      <div class="flex items-center justify-between mb-8">
        <div class="flex gap-6">
          <button
            phx-click="switch_tab"
            phx-value-tab="active"
            class={"text-sm font-medium pb-1 border-b-2 transition-colors #{if @tab == :active, do: "border-[#6F8F9D] text-[#2F2F2F]", else: "border-transparent text-[#2F2F2F]/40 hover:text-[#2F2F2F]/60"}"}
          >
            Active
          </button>
          <button
            phx-click="switch_tab"
            phx-value-tab="history"
            class={"text-sm font-medium pb-1 border-b-2 transition-colors #{if @tab == :history, do: "border-[#6F8F9D] text-[#2F2F2F]", else: "border-transparent text-[#2F2F2F]/40 hover:text-[#2F2F2F]/60"}"}
          >
            History
          </button>
        </div>
        <a
          href={~p"/questions/new"}
          class="bg-[#6F8F9D] text-white px-4 py-2 rounded-lg text-sm font-medium hover:bg-[#5a7a87] transition-colors"
        >
          Ask a question
        </a>
      </div>

      <%!-- ACTIVE TAB --%>
      <%= if @tab == :active do %>
        <%= if @active_question do %>
          <%!-- 1. ACTIVE QUESTION STATUS --%>
          <div class="mb-6">
            <p class="text-xs text-[#2F2F2F]/40 uppercase tracking-wider mb-3">Your question</p>
            <div class="bg-white border border-[#E4E6E3] rounded-lg p-5 sm:p-6">
              <p class="text-base sm:text-lg text-[#2F2F2F] leading-relaxed mb-3" style="font-family: Georgia, serif;">
                "{@active_question.text}"
              </p>
              <div class="flex flex-wrap items-center gap-2 sm:gap-3">
                <span class="text-xs font-medium px-2 py-1 rounded-full bg-[#A8BDA4]/20 text-[#6F8F6B]">
                  {Categories.label(@active_question.category)}
                </span>
                <span class="text-xs text-[#2F2F2F]/40">
                  {Calendar.strftime(@active_question.inserted_at, "%b %d, %Y")}
                </span>
                <span class={"text-xs font-medium px-2 py-1 rounded-full #{status_class(@active_question.status)}"}>
                  {length(@responses)} of {@total_expected} perspectives
                </span>
              </div>
              <div :if={@active_question.image_paths != []} class="flex gap-3 mt-4">
                <img
                  :for={path <- @active_question.image_paths}
                  src={path}
                  class="w-16 h-16 object-cover rounded-lg border border-[#E4E6E3]"
                />
              </div>
            </div>
          </div>

          <%!-- 2. RESPONSE FEED --%>
          <div class="mb-6">
            <%= if @responses != [] do %>
              <div class="space-y-4">
                <.response_card
                  :for={{response, idx} <- Enum.with_index(@responses, 1)}
                  response={response}
                  index={idx}
                  liked={interaction?(@interactions, response.id, "like")}
                  saved={interaction?(@interactions, response.id, "save")}
                />
              </div>
            <% end %>

            <%!-- Waiting placeholders --%>
            <%= if length(@responses) < @total_expected do %>
              <div class={"space-y-4 #{if @responses != [], do: "mt-4"}"}>
                <.response_card_placeholder
                  :for={idx <- (length(@responses) + 1)..@total_expected//1}
                  index={idx}
                />
              </div>
            <% end %>

            <%!-- No responses at all --%>
            <%= if @responses == [] do %>
              <div class="text-center py-10 bg-white border border-[#E4E6E3] rounded-lg mt-4">
                <p class="text-[#2F2F2F]/50 mb-1">Your question is out there.</p>
                <p class="text-sm text-[#2F2F2F]/40">Perspectives are on their way. Check back soon.</p>
              </div>
            <% end %>
          </div>

          <%!-- 3. ACTION PANEL --%>
          <div class="border-t border-[#E4E6E3] pt-6 mb-8">
            <%!-- Follow-up --%>
            <%= if @followup_count < @max_followups and length(@responses) > 0 do %>
              <div class="mb-6">
                <p class="text-sm font-medium text-[#2F2F2F] mb-3">Ask a follow-up</p>
                <.form for={%{}} phx-submit="send_followup" class="flex gap-2 sm:gap-3">
                  <input
                    type="text"
                    name="text"
                    value={@followup_text}
                    placeholder="e.g. What if we've only been on two dates?"
                    class="flex-1 border border-[#E4E6E3] rounded-lg px-3 sm:px-4 py-2.5 text-sm focus:outline-none focus:border-[#6F8F9D] focus:ring-1 focus:ring-[#6F8F9D] bg-white"
                  />
                  <button
                    type="submit"
                    class="bg-[#6F8F9D] text-white px-4 sm:px-5 py-2.5 rounded-lg text-sm font-medium hover:bg-[#5a7a87] transition-colors flex-shrink-0"
                  >
                    Send
                  </button>
                </.form>
                <p class="text-xs text-[#2F2F2F]/30 mt-2">
                  {remaining_followups(@followup_count, @max_followups)} remaining
                </p>
              </div>
            <% end %>

            <div class="flex flex-wrap items-center gap-3">
              <%= if @active_question.status == :pending and length(@responses) >= @total_expected do %>
                <button
                  phx-click="mark_resolved"
                  class="border border-[#A8BDA4] text-[#6F8F6B] px-5 py-2.5 rounded-lg text-sm font-medium hover:bg-[#A8BDA4]/10 transition-colors"
                >
                  Mark as resolved
                </button>
              <% end %>
              <a
                href={~p"/questions/new"}
                class="bg-[#6F8F9D] text-white px-5 py-2.5 rounded-lg text-sm font-medium hover:bg-[#5a7a87] transition-colors"
              >
                Ask a new question
              </a>
            </div>
          </div>

          <%!-- Other active questions --%>
          <%= if length(@active_questions) > 1 do %>
            <div class="border-t border-[#E4E6E3] pt-6">
              <p class="text-xs text-[#2F2F2F]/40 uppercase tracking-wider mb-4">Other active questions</p>
              <div class="space-y-3">
                <button
                  :for={q <- @active_questions}
                  :if={q.id != @active_question.id}
                  phx-click="select_question"
                  phx-value-id={q.id}
                  class="w-full text-left bg-white border border-[#E4E6E3] rounded-lg p-4 hover:border-[#6F8F9D] transition-colors"
                >
                  <p class="text-sm text-[#2F2F2F] truncate">{q.text}</p>
                  <div class="flex items-center gap-2 mt-2">
                    <span class="text-xs text-[#2F2F2F]/40">
                      {Calendar.strftime(q.inserted_at, "%b %d")}
                    </span>
                    <span class={"text-xs font-medium px-2 py-0.5 rounded-full #{status_class(q.status)}"}>
                      {q.status |> to_string() |> String.capitalize()}
                    </span>
                  </div>
                </button>
              </div>
            </div>
          <% end %>

        <% else %>
          <div class="text-center py-16 bg-white border border-[#E4E6E3] rounded-lg">
            <p class="text-[#2F2F2F]/50 mb-4">No active questions right now.</p>
            <a href={~p"/questions/new"} class="text-[#6F8F9D] hover:underline text-sm">
              Ask your first question
            </a>
          </div>
        <% end %>
      <% end %>

      <%!-- HISTORY TAB --%>
      <%= if @tab == :history do %>
        <%= if @history_questions == [] do %>
          <div class="text-center py-16 bg-white border border-[#E4E6E3] rounded-lg">
            <p class="text-[#2F2F2F]/50">No past questions yet.</p>
          </div>
        <% else %>
          <div class="space-y-4">
            <div
              :for={q <- @history_questions}
              class="bg-white border border-[#E4E6E3] rounded-lg"
            >
              <button
                phx-click="toggle_history"
                phx-value-id={q.id}
                class="w-full text-left p-4 sm:p-5 hover:bg-[#F7F7F5]/50 transition-colors"
              >
                <div class="flex flex-wrap items-center gap-2 mb-2">
                  <span class="text-xs font-medium px-2 py-1 rounded-full bg-[#A8BDA4]/20 text-[#6F8F6B]">
                    {Categories.label(q.category)}
                  </span>
                  <span class={"text-xs font-medium px-2 py-1 rounded-full #{status_class(q.status)}"}>
                    {q.status |> to_string() |> String.capitalize()}
                  </span>
                  <span class="text-xs text-[#2F2F2F]/40 ml-auto">
                    {Calendar.strftime(q.inserted_at, "%b %d, %Y")}
                  </span>
                </div>
                <p class="text-sm text-[#2F2F2F]">{q.text}</p>
                <p class="text-xs text-[#6F8F9D] mt-2">
                  <%= if MapSet.member?(@expanded_history, q.id), do: "Hide responses", else: "Show responses" %>
                </p>
              </button>

              <%= if MapSet.member?(@expanded_history, q.id) do %>
                <div class="border-t border-[#E4E6E3] p-4 sm:p-5 bg-[#F7F7F5]/30">
                  <% history_responses = Map.get(@history_data, q.id, []) %>
                  <%= if history_responses == [] do %>
                    <p class="text-sm text-[#2F2F2F]/40">No responses received.</p>
                  <% else %>
                    <div class="space-y-4">
                      <.response_card
                        :for={{response, idx} <- Enum.with_index(history_responses, 1)}
                        response={response}
                        index={idx}
                        liked={interaction?(@interactions, response.id, "like")}
                        saved={interaction?(@interactions, response.id, "save")}
                      />
                    </div>
                  <% end %>
                </div>
              <% end %>
            </div>
          </div>
        <% end %>
      <% end %>
    </div>
    """
  end

  # --- Events ---

  @impl true
  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :tab, String.to_existing_atom(tab))}
  end

  @impl true
  def handle_event("select_question", %{"id" => id}, socket) do
    user = socket.assigns.current_scope.user
    question = Questions.get_question_with_responses!(id)
    responses = Enum.take(question.responses, @max_perspectives)
    interactions = load_interactions(user.id, responses)

    {:noreply,
     socket
     |> assign(:active_question, question)
     |> assign(:responses, responses)
     |> assign(:interactions, interactions)
     |> assign(:followup_text, "")
     |> assign(:followup_count, 0)}
  end

  @impl true
  def handle_event("toggle_history", %{"id" => id}, socket) do
    expanded =
      if MapSet.member?(socket.assigns.expanded_history, id) do
        MapSet.delete(socket.assigns.expanded_history, id)
      else
        MapSet.put(socket.assigns.expanded_history, id)
      end

    # Load response data for newly expanded questions
    history_data =
      if MapSet.member?(expanded, id) and not Map.has_key?(socket.assigns.history_data, id) do
        loaded = Questions.get_question_with_responses!(id)
        user = socket.assigns.current_scope.user
        response_ids = Enum.map(loaded.responses, & &1.id)
        new_interactions = Questions.list_interactions_for_user(user.id, response_ids)

        socket = assign(socket, :interactions, Map.merge(socket.assigns.interactions, new_interactions))
        Map.put(socket.assigns.history_data, id, loaded.responses)
      else
        socket.assigns.history_data
      end

    {:noreply,
     socket
     |> assign(:expanded_history, expanded)
     |> assign(:history_data, history_data)}
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
  def handle_event("send_followup", %{"text" => text}, socket) do
    text = String.trim(text)

    if text == "" do
      {:noreply, socket}
    else
      user = socket.assigns.current_scope.user
      original = socket.assigns.active_question

      attrs = %{
        "text" => text,
        "category" => to_string(original.category),
        "image_paths" => []
      }

      case Questions.create_question(user, attrs) do
        {:ok, new_q} ->
          if connected?(socket) do
            Phoenix.PubSub.subscribe(WorthAsking.PubSub, "question:#{new_q.id}")
          end

          questions = Questions.list_questions_for_user(user.id)
          {active, history} = split_questions(questions)

          {:noreply,
           socket
           |> assign(:questions, questions)
           |> assign(:active_questions, active)
           |> assign(:history_questions, history)
           |> assign(:followup_text, "")
           |> update(:followup_count, &(&1 + 1))
           |> put_flash(:info, "Follow-up sent. You'll get new perspectives soon.")}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Could not send follow-up. Try again.")}
      end
    end
  end

  @impl true
  def handle_event("mark_resolved", _params, socket) do
    question = socket.assigns.active_question

    case Questions.update_question_status(question, :answered) do
      {:ok, _} ->
        user = socket.assigns.current_scope.user
        questions = Questions.list_questions_for_user(user.id)
        {active, history} = split_questions(questions)
        active_question = load_active_question(active)
        responses = get_responses(active_question)
        interactions = load_interactions(user.id, responses)

        {:noreply,
         socket
         |> assign(:questions, questions)
         |> assign(:active_questions, active)
         |> assign(:history_questions, history)
         |> assign(:active_question, active_question)
         |> assign(:responses, responses)
         |> assign(:interactions, interactions)
         |> put_flash(:info, "Question marked as resolved.")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not update question.")}
    end
  end

  # --- PubSub ---

  @impl true
  def handle_info({:new_response, response}, socket) do
    active = socket.assigns.active_question

    if active && response.question_id == active.id do
      user = socket.assigns.current_scope.user
      question = Questions.get_question_with_responses!(active.id)
      responses = Enum.take(question.responses, @max_perspectives)
      interactions = load_interactions(user.id, responses)

      {:noreply,
       socket
       |> assign(:active_question, question)
       |> assign(:responses, responses)
       |> assign(:interactions, interactions)}
    else
      user = socket.assigns.current_scope.user
      questions = Questions.list_questions_for_user(user.id)
      {active_qs, history} = split_questions(questions)

      {:noreply,
       socket
       |> assign(:questions, questions)
       |> assign(:active_questions, active_qs)
       |> assign(:history_questions, history)}
    end
  end

  @impl true
  def handle_info({:response_ready, _question}, socket) do
    user = socket.assigns.current_scope.user
    questions = Questions.list_questions_for_user(user.id)
    {active, history} = split_questions(questions)

    {:noreply,
     socket
     |> assign(:questions, questions)
     |> assign(:active_questions, active)
     |> assign(:history_questions, history)}
  end

  # --- Helpers ---

  defp split_questions(questions) do
    Enum.split_with(questions, fn q -> q.status in [:pending, :paid] end)
  end

  defp load_active_question([]), do: nil
  defp load_active_question([most_recent | _]) do
    Questions.get_question_with_responses!(most_recent.id)
  end

  defp get_responses(nil), do: []
  defp get_responses(question), do: Enum.take(question.responses, @max_perspectives)

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
    all_response_ids =
      Enum.map(socket.assigns.responses, & &1.id) ++
      (socket.assigns.history_data |> Map.values() |> List.flatten() |> Enum.map(& &1.id))

    interactions = Questions.list_interactions_for_user(user.id, all_response_ids)
    assign(socket, :interactions, interactions)
  end

  defp status_class(:pending), do: "bg-yellow-50 text-yellow-700"
  defp status_class(:paid), do: "bg-yellow-50 text-yellow-700"
  defp status_class(:answered), do: "bg-green-50 text-green-700"

  defp remaining_followups(count, max) do
    remaining = max - count
    if remaining == 1, do: "#{remaining} follow-up", else: "#{remaining} follow-ups"
  end
end
