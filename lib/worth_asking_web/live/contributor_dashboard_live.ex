defmodule WorthAskingWeb.ContributorDashboardLive do
  use WorthAskingWeb, :live_view

  alias WorthAsking.Questions
  alias WorthAsking.Contributors
  alias WorthAsking.Notifications

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    profile = Contributors.get_profile_by_user(user.id)

    cond do
      is_nil(profile) ->
        {:ok,
         socket
         |> put_flash(:error, "You don't have a contributor profile.")
         |> redirect(to: ~p"/")}

      not profile.onboarding_completed ->
        {:ok, push_navigate(socket, to: ~p"/contributors/onboarding")}

      true ->
      available_questions = Questions.list_available_questions_for_contributor(profile)
      my_responses = Questions.list_responses_by_contributor(user.id)

      if connected?(socket) do
        for category <- profile.categories do
          Phoenix.PubSub.subscribe(WorthAsking.PubSub, "questions:#{category}")
        end
        Phoenix.PubSub.subscribe(WorthAsking.PubSub, "contributor:#{user.id}")
      end

      {:ok,
       socket
       |> assign(:page_title, "Contributor Dashboard")
       |> assign(:profile, profile)
       |> assign(:available_questions, available_questions)
       |> assign(:my_responses, my_responses)}
    end
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

      <%!-- Availability toggle --%>
      <div class="bg-white border border-[#E4E6E3] rounded-lg p-6 mb-8">
        <div class="flex items-center justify-between mb-4">
          <div>
            <p class="font-medium text-[#2F2F2F]">Availability</p>
            <p class="text-xs text-[#2F2F2F]/50 mt-0.5">
              <%= if @profile.available_now do %>
                You're available
                <%= if @profile.available_until do %>
                  &mdash; auto-expires {format_expiry(@profile.available_until)}
                <% end %>
              <% else %>
                You're currently offline
              <% end %>
            </p>
          </div>
          <button
            phx-click="toggle_availability"
            class={[
              "relative inline-flex h-7 w-12 items-center rounded-full transition-colors",
              if(@profile.available_now, do: "bg-[#6F8F6B]", else: "bg-[#E4E6E3]")
            ]}
          >
            <span class={[
              "inline-block h-5 w-5 transform rounded-full bg-white transition-transform shadow-sm",
              if(@profile.available_now, do: "translate-x-6", else: "translate-x-1")
            ]} />
          </button>
        </div>

        <div class="border-t border-[#E4E6E3] pt-4">
          <p class="text-xs text-[#2F2F2F]/50 uppercase tracking-wider mb-3">Session types</p>
          <div class="flex flex-wrap gap-2">
            <button
              phx-click="toggle_session_type"
              phx-value-type="basic"
              class={[
                "px-3 py-1.5 rounded-full text-xs font-medium border transition-colors",
                if(@profile.accept_basic,
                  do: "bg-[#A8BDA4]/20 border-[#A8BDA4] text-[#6F8F6B]",
                  else: "bg-white border-[#E4E6E3] text-[#2F2F2F]/40")
              ]}
            >
              Basic
            </button>
            <button
              phx-click="toggle_session_type"
              phx-value-type="interactive"
              class={[
                "px-3 py-1.5 rounded-full text-xs font-medium border transition-colors",
                if(@profile.accept_interactive,
                  do: "bg-[#A8BDA4]/20 border-[#A8BDA4] text-[#6F8F6B]",
                  else: "bg-white border-[#E4E6E3] text-[#2F2F2F]/40")
              ]}
            >
              Interactive
            </button>
            <button
              phx-click="toggle_session_type"
              phx-value-type="fast"
              class={[
                "px-3 py-1.5 rounded-full text-xs font-medium border transition-colors",
                if(@profile.accept_fast,
                  do: "bg-[#A8BDA4]/20 border-[#A8BDA4] text-[#6F8F6B]",
                  else: "bg-white border-[#E4E6E3] text-[#2F2F2F]/40")
              ]}
            >
              Fast Perspective
            </button>
          </div>
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
  def handle_event("toggle_availability", _params, socket) do
    profile = socket.assigns.profile
    new_available = !profile.available_now

    case Notifications.toggle_availability(profile, new_available) do
      {:ok, updated_profile} ->
        {:noreply, assign(socket, :profile, updated_profile)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not update availability.")}
    end
  end

  @impl true
  def handle_event("toggle_session_type", %{"type" => type}, socket) do
    profile = socket.assigns.profile

    attrs =
      case type do
        "basic" -> %{accept_basic: !profile.accept_basic}
        "interactive" -> %{accept_interactive: !profile.accept_interactive}
        "fast" -> %{accept_fast: !profile.accept_fast}
        _ -> %{}
      end

    case Notifications.update_session_preferences(profile, attrs) do
      {:ok, updated_profile} ->
        {:noreply, assign(socket, :profile, updated_profile)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not update preferences.")}
    end
  end

  @impl true
  def handle_info({:new_question, question}, socket) do
    updated = [question | socket.assigns.available_questions]
    {:noreply, assign(socket, :available_questions, updated)}
  end

  @impl true
  def handle_info({:new_question_alert, question}, socket) do
    updated = [question | socket.assigns.available_questions]
    {:noreply,
     socket
     |> assign(:available_questions, updated)
     |> put_flash(:info, "New question available!")}
  end

  defp format_expiry(nil), do: ""
  defp format_expiry(datetime) do
    diff = DateTime.diff(datetime, DateTime.utc_now(), :minute)

    cond do
      diff <= 0 -> "expired"
      diff < 60 -> "in #{diff}m"
      diff < 1440 -> "in #{div(diff, 60)}h"
      true -> Calendar.strftime(datetime, "%b %d at %I:%M %p")
    end
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
