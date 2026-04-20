defmodule WorthAskingWeb.Admin.AdminApplicationsLive do
  use WorthAskingWeb, :live_view

  alias WorthAsking.Contributors
  alias WorthAsking.Accounts

  @impl true
  def mount(_params, _session, socket) do
    applications = Contributors.list_pending_applications()

    socket =
      socket
      |> assign(:page_title, "Contributor Applications")
      |> assign(:applications, applications)
      |> assign(:expanded, MapSet.new())

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto px-6 py-12">
      <a href={~p"/admin"} class="text-sm text-[#6F8F9D] hover:underline mb-8 inline-block">
        &larr; Back to Dashboard
      </a>

      <h1 class="text-3xl font-semibold text-[#2F2F2F] mb-8" style="font-family: Georgia, serif;">
        Contributor Applications
      </h1>

      <%= if @applications == [] do %>
        <div class="border border-[#E4E6E3] rounded-lg p-8 text-center bg-white">
          <p class="text-[#2F2F2F]/60">No pending applications.</p>
        </div>
      <% else %>
        <div class="space-y-6">
          <div
            :for={profile <- @applications}
            class="border border-[#E4E6E3] rounded-lg bg-white"
          >
            <%!-- Header --%>
            <div class="p-6 pb-4">
              <div class="flex items-start justify-between mb-4">
                <div>
                  <h2 class="text-lg font-semibold text-[#2F2F2F]" style="font-family: Georgia, serif;">
                    {profile.display_name}
                  </h2>
                  <p class="text-sm text-[#2F2F2F]/50">{profile.user.email}</p>
                </div>
                <div class="flex items-center gap-3">
                  <%= if judgment_score(profile) do %>
                    <span class={"text-xs font-medium px-2 py-1 rounded-full #{score_class(judgment_score(profile))}"}>
                      Judgment: {judgment_score(profile)}/9
                    </span>
                  <% end %>
                  <span class="text-xs bg-yellow-50 text-yellow-700 px-2 py-1 rounded-full">
                    Pending
                  </span>
                </div>
              </div>

              <%!-- Bio --%>
              <%= if profile.bio do %>
                <div class="mb-4">
                  <p class="text-xs text-[#2F2F2F]/50 uppercase tracking-wide mb-1">Bio</p>
                  <p class="text-sm text-[#2F2F2F]">{profile.bio}</p>
                </div>
              <% end %>

              <%!-- Motivation --%>
              <%= if get_motivation(profile) do %>
                <div class="mb-4">
                  <p class="text-xs text-[#2F2F2F]/50 uppercase tracking-wide mb-1">Why they want to be a contributor</p>
                  <p class="text-sm text-[#2F2F2F]/80 italic">{get_motivation(profile)}</p>
                </div>
              <% end %>

              <%!-- Categories --%>
              <div class="mb-4">
                <p class="text-xs text-[#2F2F2F]/50 uppercase tracking-wide mb-1">Categories</p>
                <div class="flex flex-wrap gap-2">
                  <span
                    :for={cat <- profile.categories}
                    class="text-xs border border-[#E4E6E3] text-[#2F2F2F]/70 px-2 py-1 rounded-full"
                  >
                    {cat |> to_string() |> String.replace("_", " ") |> String.capitalize()}
                  </span>
                </div>
              </div>

              <%!-- Expand/collapse toggle --%>
              <button
                phx-click="toggle_expand"
                phx-value-profile-id={profile.id}
                class="text-xs text-[#6F8F9D] hover:underline"
              >
                <%= if MapSet.member?(@expanded, profile.id) do %>
                  Hide responses
                <% else %>
                  Show scenario responses & judgment answers
                <% end %>
              </button>
            </div>

            <%!-- Expanded: scenario responses and judgment --%>
            <%= if MapSet.member?(@expanded, profile.id) do %>
              <div class="border-t border-[#E4E6E3] p-6 bg-[#F7F7F5]/50">
                <%!-- Scenario responses --%>
                <%= if get_scenarios(profile) != [] do %>
                  <div class="mb-6">
                    <p class="text-xs text-[#2F2F2F]/50 uppercase tracking-wide mb-3">
                      Scenario Responses
                    </p>
                    <div class="space-y-4">
                      <div :for={scenario <- get_scenarios(profile)} class="border-l-2 border-[#A8BDA4] pl-4">
                        <p class="text-xs text-[#2F2F2F]/40 mb-1">{Map.get(scenario, "evaluates", "")}</p>
                        <p class="text-sm font-medium text-[#2F2F2F]/70 mb-2 italic">
                          "{Map.get(scenario, "scenario", "")}"
                        </p>
                        <p class="text-sm text-[#2F2F2F]">
                          {Map.get(scenario, "response", "")}
                        </p>
                      </div>
                    </div>
                  </div>
                <% end %>

                <%!-- Judgment answers --%>
                <%= if get_judgment(profile) != [] do %>
                  <div>
                    <p class="text-xs text-[#2F2F2F]/50 uppercase tracking-wide mb-3">
                      Situational Judgment
                    </p>
                    <div class="space-y-3">
                      <div :for={jq <- get_judgment(profile)} class="text-sm">
                        <p class="text-[#2F2F2F]/60 mb-1">{Map.get(jq, "question", "")}</p>
                        <p class="text-[#2F2F2F] font-medium">
                          Chose: {Map.get(jq, "answer", "?")}
                        </p>
                      </div>
                    </div>
                  </div>
                <% end %>
              </div>
            <% end %>

            <%!-- Actions --%>
            <div class="flex gap-3 p-6 pt-4 border-t border-[#E4E6E3]">
              <button
                phx-click="approve"
                phx-value-profile-id={profile.id}
                class="px-4 py-2 bg-[#6F8F6B] text-white text-sm rounded-md hover:bg-[#5d7a5a] transition-colors"
              >
                Approve
              </button>
              <button
                phx-click="reject"
                phx-value-profile-id={profile.id}
                class="px-4 py-2 border border-[#E4E6E3] text-[#2F2F2F]/70 text-sm rounded-md hover:border-red-300 hover:text-red-600 transition-colors"
              >
                Reject
              </button>
            </div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  @impl true
  def handle_event("toggle_expand", %{"profile-id" => profile_id}, socket) do
    expanded =
      if MapSet.member?(socket.assigns.expanded, profile_id) do
        MapSet.delete(socket.assigns.expanded, profile_id)
      else
        MapSet.put(socket.assigns.expanded, profile_id)
      end

    {:noreply, assign(socket, :expanded, expanded)}
  end

  @impl true
  def handle_event("approve", %{"profile-id" => profile_id}, socket) do
    profile = Enum.find(socket.assigns.applications, &(&1.id == profile_id))

    case Contributors.approve_contributor(profile) do
      {:ok, approved_profile} ->
        # Send approval email with onboarding magic link
        user = approved_profile.user
        Accounts.deliver_approval_notification(
          user,
          &(WorthAskingWeb.Endpoint.url() <> "/users/log-in/#{&1}")
        )

        applications = Contributors.list_pending_applications()

        {:noreply,
         socket
         |> assign(:applications, applications)
         |> put_flash(:info, "#{profile.display_name} approved. Onboarding email sent.")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to approve application.")}
    end
  end

  @impl true
  def handle_event("reject", %{"profile-id" => profile_id}, socket) do
    profile = Enum.find(socket.assigns.applications, &(&1.id == profile_id))

    case Contributors.reject_contributor(profile) do
      {:ok, _profile} ->
        applications = Contributors.list_pending_applications()

        {:noreply,
         socket
         |> assign(:applications, applications)
         |> put_flash(:info, "#{profile.display_name} rejected.")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to reject application.")}
    end
  end

  # --- Helpers to extract structured data from sample_responses map ---

  defp judgment_score(profile) do
    case profile.sample_responses do
      %{"judgment_score" => score} when is_integer(score) -> score
      _ -> nil
    end
  end

  defp get_motivation(profile) do
    case profile.sample_responses do
      %{"motivation" => m} when is_binary(m) and m != "" -> m
      _ -> nil
    end
  end

  defp get_scenarios(profile) do
    case profile.sample_responses do
      %{"scenarios" => scenarios} when is_list(scenarios) -> scenarios
      _ -> []
    end
  end

  defp get_judgment(profile) do
    case profile.sample_responses do
      %{"judgment" => judgment} when is_list(judgment) -> judgment
      _ -> []
    end
  end

  defp score_class(score) when score >= 7, do: "bg-green-50 text-green-700"
  defp score_class(score) when score >= 4, do: "bg-yellow-50 text-yellow-700"
  defp score_class(_score), do: "bg-red-50 text-red-700"
end
