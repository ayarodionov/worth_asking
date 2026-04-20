defmodule WorthAskingWeb.MyQuestionsLive do
  use WorthAskingWeb, :live_view

  alias WorthAsking.Questions

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    questions = Questions.list_questions_for_user(user.id)

    if connected?(socket) do
      Phoenix.PubSub.subscribe(WorthAsking.PubSub, "user:#{user.id}")
    end

    socket =
      socket
      |> assign(:page_title, "My Questions")
      |> assign(:questions, questions)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-xl mx-auto px-6 py-12">
      <div class="flex items-center justify-between mb-8">
        <h1 class="text-2xl font-semibold" style="font-family: Georgia, serif;">
          My Questions
        </h1>
        <a
          href={~p"/questions/new"}
          class="bg-[#6F8F9D] text-white px-4 py-2 rounded-lg text-sm font-medium hover:bg-[#5a7a87] transition-colors"
        >
          Ask a question
        </a>
      </div>

      <%= if @questions == [] do %>
        <div class="text-center py-16 bg-white border border-[#E4E6E3] rounded-lg">
          <p class="text-[#2F2F2F]/50 mb-4">You haven't asked anything yet.</p>
          <a href={~p"/questions/new"} class="text-[#6F8F9D] hover:underline text-sm">
            Ask your first question
          </a>
        </div>
      <% else %>
        <div class="space-y-4">
          <a
            :for={question <- @questions}
            href={~p"/questions/#{question.id}"}
            class="block bg-white border border-[#E4E6E3] rounded-lg p-5 hover:border-[#6F8F9D] transition-colors"
          >
            <div class="flex items-center gap-2 mb-2">
              <span class="text-xs font-medium px-2 py-1 rounded-full bg-[#A8BDA4]/20 text-[#6F8F6B]">
                {format_category(question.category)}
              </span>
              <span class={"text-xs font-medium px-2 py-1 rounded-full #{status_class(question.status)}"}>
                {question.status |> to_string() |> String.capitalize()}
              </span>
              <span :if={question.image_paths != []} class="text-xs text-[#6F8F9D]">
                {length(question.image_paths)} image(s)
              </span>
            </div>
            <p class="text-sm">{question.text}</p>
            <p class="text-xs text-[#2F2F2F]/40 mt-2">
              {Calendar.strftime(question.inserted_at, "%b %d, %Y")}
            </p>
          </a>
        </div>
      <% end %>
    </div>
    """
  end

  @impl true
  def handle_info({:response_ready, _question}, socket) do
    user = socket.assigns.current_scope.user
    questions = Questions.list_questions_for_user(user.id)
    {:noreply, assign(socket, :questions, questions)}
  end

  defp format_category(cat), do: WorthAsking.Categories.label(cat)

  defp status_class(:pending), do: "bg-yellow-50 text-yellow-700"
  defp status_class(:answered), do: "bg-blue-50 text-blue-700"
  defp status_class(:paid), do: "bg-green-50 text-green-700"
end
