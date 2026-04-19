defmodule WorthAskingWeb.QuestionShowLive do
  use WorthAskingWeb, :live_view

  alias WorthAsking.Questions
  alias WorthAsking.Contributors

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    question = Questions.get_question_with_responses!(id)
    user = socket.assigns.current_scope.user
    paid = Questions.question_paid?(question.id, user.id)

    if connected?(socket) do
      Phoenix.PubSub.subscribe(WorthAsking.PubSub, "question:#{question.id}")
    end

    socket =
      socket
      |> assign(:page_title, "Your Question")
      |> assign(:question, question)
      |> assign(:paid, paid)
      |> assign(:rating_submitted, MapSet.new())

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-xl mx-auto px-6 py-12">
      <a href={~p"/my-questions"} class="text-sm text-[#6F8F9D] hover:underline mb-8 inline-block">
        &larr; My questions
      </a>

      <div class="bg-white border border-[#E4E6E3] rounded-lg p-6 mb-8">
        <div class="flex items-center gap-2 mb-3">
          <span class="text-xs font-medium px-2 py-1 rounded-full bg-[#A8BDA4]/20 text-[#6F8F6B]">
            {format_category(@question.category)}
          </span>
          <span class={"text-xs font-medium px-2 py-1 rounded-full #{status_class(@question.status)}"}>
            {@question.status |> to_string() |> String.capitalize()}
          </span>
        </div>
        <p class="text-base font-medium">{@question.text}</p>

        <%!-- Attached images --%>
        <div :if={@question.image_paths != []} class="flex gap-3 mt-4">
          <img
            :for={path <- @question.image_paths}
            src={path}
            class="w-24 h-24 object-cover rounded-lg border border-[#E4E6E3]"
          />
        </div>
      </div>

      <h2 class="text-sm font-medium text-[#2F2F2F]/50 uppercase tracking-wider mb-4">
        Responses ({length(@question.responses)})
      </h2>

      <%= if @question.responses == [] do %>
        <div class="text-center py-12 bg-white border border-[#E4E6E3] rounded-lg">
          <p class="text-[#2F2F2F]/50">Waiting for responses from contributors...</p>
        </div>
      <% else %>
        <div class="space-y-4">
          <div :for={response <- @question.responses} class="bg-white border border-[#E4E6E3] rounded-lg p-6">
            <%= if @paid do %>
              <p class="text-sm leading-relaxed text-[#2F2F2F]/80 mb-4">{response.text}</p>

              <%!-- Rating stars --%>
              <div class="border-t border-[#E4E6E3] pt-3 mt-3">
                <%= if MapSet.member?(@rating_submitted, response.id) do %>
                  <p class="text-xs text-[#A8BDA4]">Thank you for your rating</p>
                <% else %>
                  <p class="text-xs text-[#2F2F2F]/40 mb-2">Rate this response</p>
                  <div class="flex gap-1">
                    <button
                      :for={star <- 1..5}
                      phx-click="rate"
                      phx-value-response-id={response.id}
                      phx-value-score={star}
                      class="text-[#6F8F9D] hover:text-[#5a7a87] transition-colors"
                    >
                      <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
                        <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" />
                      </svg>
                    </button>
                  </div>
                <% end %>
              </div>
            <% else %>
              <div class="relative">
                <p class="text-sm leading-relaxed response-blurred">{response.text}</p>
                <div class="absolute inset-0 flex items-center justify-center">
                  <a
                    href={~p"/stripe/checkout/#{@question.id}"}
                    class="bg-[#6F8F9D] text-white px-4 py-2 rounded-lg text-sm font-medium hover:bg-[#5a7a87] transition-colors"
                  >
                    Unlock responses
                  </a>
                </div>
              </div>
            <% end %>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  @impl true
  def handle_event("rate", %{"response-id" => response_id, "score" => score}, socket) do
    user = socket.assigns.current_scope.user
    response = Enum.find(socket.assigns.question.responses, &(&1.id == response_id))
    {score_int, _} = Integer.parse(score)

    case Questions.rate_response(response, user, score_int) do
      {:ok, _rating} ->
        # Update contributor stats
        if response.contributor_id do
          Contributors.update_profile_stats(response.contributor_id)
        end

        {:noreply,
         socket
         |> update(:rating_submitted, &MapSet.put(&1, response_id))}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not save rating")}
    end
  end

  @impl true
  def handle_info({:new_response, _response}, socket) do
    question = Questions.get_question_with_responses!(socket.assigns.question.id)
    {:noreply, assign(socket, :question, question)}
  end

  defp format_category(cat) do
    cat |> to_string() |> String.replace("_", " ") |> String.split(" ") |> Enum.map(&String.capitalize/1) |> Enum.join(" ")
  end

  defp status_class(:pending), do: "bg-yellow-50 text-yellow-700"
  defp status_class(:answered), do: "bg-blue-50 text-blue-700"
  defp status_class(:paid), do: "bg-green-50 text-green-700"
end
