defmodule WorthAskingWeb.ContributorDashboardLive do
  use WorthAskingWeb, :live_view

  alias WorthAsking.Questions
  alias WorthAsking.Contributors

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    profile = Contributors.get_profile_by_user(user.id)

    available_questions = Questions.list_available_questions_for_contributor(profile)
    my_responses = Questions.list_responses_by_contributor(user.id)

    if connected?(socket) do
      for category <- profile.categories do
        Phoenix.PubSub.subscribe(WorthAsking.PubSub, "questions:#{category}")
      end
    end

    socket =
      socket
      |> assign(:page_title, "Contributor Dashboard")
      |> assign(:profile, profile)
      |> assign(:available_questions, available_questions)
      |> assign(:my_responses, my_responses)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-3xl mx-auto px-6 py-12" style="background-color: #F7F7F5; min-height: 100vh;">
      <div class="flex items-start justify-between mb-10">
        <div>
          <h1 class="text-2xl font-semibold text-[#2F2F2F]" style="font-family: Georgia, serif;">
            Dashboard
          </h1>
          <p class="text-sm text-[#2F2F2F]/60 mt-1">
            Welcome back, {@profile.display_name}
          </p>
        </div>
        <div class="bg-white border border-[#E4E6E3] rounded-lg px-5 py-4 text-center">
          <p class="text-xs text-[#2F2F2F]/50 uppercase tracking-wider mb-1">Earnings</p>
          <p class="text-xl font-semibold text-[#2F2F2F]">
            ${format_cents(@profile.earnings_cents)}
          </p>
        </div>
      </div>

      <%!-- Available questions --%>
      <section class="mb-12">
        <h2 class="text-sm font-medium text-[#2F2F2F]/50 uppercase tracking-wider mb-4">
          Available Questions ({length(@available_questions)})
        </h2>

        <%= if @available_questions == [] do %>
          <div class="bg-white border border-[#E4E6E3] rounded-lg p-8 text-center">
            <p class="text-sm text-[#2F2F2F]/50">No questions available right now. Check back soon.</p>
          </div>
        <% else %>
          <div class="space-y-3">
            <div :for={question <- @available_questions} class="bg-white border border-[#E4E6E3] rounded-lg p-5 hover:border-[#A8BDA4] transition-colors">
              <div class="flex items-start justify-between gap-4">
                <div class="flex-1 min-w-0">
                  <div class="flex items-center gap-2 mb-2">
                    <span class="text-xs font-medium px-2 py-1 rounded-full bg-[#A8BDA4]/20 text-[#6F8F6B] shrink-0">
                      {question.category |> to_string() |> String.replace("_", " ") |> String.split(" ") |> Enum.map(&String.capitalize/1) |> Enum.join(" ")}
                    </span>
                    <span class="text-xs text-[#2F2F2F]/40">
                      {time_ago(question.inserted_at)}
                    </span>
                  </div>
                  <p class="text-sm text-[#2F2F2F] leading-relaxed">{question.text}</p>
                </div>
                <a
                  href={~p"/dashboard/respond/#{question.id}"}
                  class="shrink-0 bg-[#6F8F9D] text-white px-4 py-2 rounded-lg text-sm font-medium hover:bg-[#5a7a87] transition-colors"
                >
                  Respond
                </a>
              </div>
            </div>
          </div>
        <% end %>
      </section>

      <%!-- My responses --%>
      <section>
        <h2 class="text-sm font-medium text-[#2F2F2F]/50 uppercase tracking-wider mb-4">
          My Responses ({length(@my_responses)})
        </h2>

        <%= if @my_responses == [] do %>
          <div class="bg-white border border-[#E4E6E3] rounded-lg p-8 text-center">
            <p class="text-sm text-[#2F2F2F]/50">You haven't responded to any questions yet.</p>
          </div>
        <% else %>
          <div class="space-y-3">
            <div :for={response <- @my_responses} class="bg-white border border-[#E4E6E3] rounded-lg p-5">
              <div class="flex items-center gap-2 mb-2">
                <span class="text-xs font-medium px-2 py-1 rounded-full bg-[#6F8F9D]/10 text-[#6F8F9D]">
                  Responded
                </span>
                <span class="text-xs text-[#2F2F2F]/40">
                  {time_ago(response.inserted_at)}
                </span>
              </div>
              <p class="text-sm text-[#2F2F2F]/70 leading-relaxed line-clamp-2">{response.text}</p>
            </div>
          </div>
        <% end %>
      </section>
    </div>
    """
  end

  @impl true
  def handle_info({:new_question, question}, socket) do
    updated = [question | socket.assigns.available_questions]
    {:noreply, assign(socket, :available_questions, updated)}
  end

  defp format_cents(nil), do: "0.00"
  defp format_cents(cents) when is_integer(cents) do
    dollars = div(cents, 100)
    remainder = rem(cents, 100)
    "#{dollars}.#{String.pad_leading(Integer.to_string(remainder), 2, "0")}"
  end

  defp time_ago(nil), do: ""
  defp time_ago(datetime) do
    diff = NaiveDateTime.diff(NaiveDateTime.utc_now(), datetime, :second)

    cond do
      diff < 60 -> "just now"
      diff < 3600 -> "#{div(diff, 60)}m ago"
      diff < 86400 -> "#{div(diff, 3600)}h ago"
      diff < 604_800 -> "#{div(diff, 86400)}d ago"
      true -> Calendar.strftime(datetime, "%b %d")
    end
  end
end
