defmodule WorthAskingWeb.Admin.AdminContributorsLive do
  use WorthAskingWeb, :live_view

  alias WorthAsking.Contributors

  @impl true
  def mount(_params, _session, socket) do
    contributors = Contributors.list_approved_contributors()

    socket =
      socket
      |> assign(:page_title, "Contributors")
      |> assign(:contributors, contributors)
      |> assign(:pause_modal, nil)
      |> assign(:pause_reason, "")

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-5xl mx-auto px-6 py-12">
      <a href={~p"/admin"} class="text-sm text-[#6F8F9D] hover:underline mb-8 inline-block">
        &larr; Back to Dashboard
      </a>

      <div class="flex items-center justify-between mb-8">
        <h1 class="text-3xl font-semibold text-[#2F2F2F]" style="font-family: Georgia, serif;">
          Contributors
        </h1>
        <div class="flex items-center gap-4 text-sm text-[#2F2F2F]/50">
          <span>{length(@contributors)} total</span>
          <span>{Enum.count(@contributors, & &1.paused)} paused</span>
          <span>{Enum.count(@contributors, & &1.available_now)} online</span>
        </div>
      </div>

      <%= if @contributors == [] do %>
        <div class="border border-[#E4E6E3] rounded-lg p-8 text-center bg-white">
          <p class="text-[#2F2F2F]/60">No approved contributors yet.</p>
        </div>
      <% else %>
        <div class="space-y-3">
          <div
            :for={profile <- @contributors}
            class={[
              "bg-white border rounded-lg p-5",
              if(profile.paused, do: "border-red-200 bg-red-50/30", else: "border-[#E4E6E3]")
            ]}
          >
            <div class="flex items-start justify-between gap-4">
              <%!-- Left: contributor info --%>
              <div class="flex-1 min-w-0">
                <div class="flex items-center gap-3 mb-2">
                  <h2 class="text-base font-semibold text-[#2F2F2F]">
                    {profile.display_name}
                  </h2>
                  <%= if profile.paused do %>
                    <span class="text-xs font-medium px-2 py-0.5 rounded-full bg-red-100 text-red-700">
                      Paused
                    </span>
                  <% end %>
                  <%= if profile.available_now and not profile.paused do %>
                    <span class="text-xs font-medium px-2 py-0.5 rounded-full bg-green-100 text-green-700">
                      Online
                    </span>
                  <% end %>
                </div>

                <p class="text-xs text-[#2F2F2F]/50 mb-2">{profile.user.email}</p>

                <%!-- Stats row --%>
                <div class="flex flex-wrap items-center gap-4 text-xs text-[#2F2F2F]/50">
                  <span>{profile.response_count} responses</span>
                  <span>${format_cents(profile.earnings_cents)} earned</span>
                  <%= if profile.average_rating do %>
                    <span>{Float.round(profile.average_rating, 1)} avg rating</span>
                  <% end %>
                  <span>Sessions: {profile.active_session_count}/{profile.max_active_sessions}</span>
                </div>

                <%!-- Categories --%>
                <div class="flex flex-wrap gap-1.5 mt-3">
                  <span
                    :for={cat <- profile.categories}
                    class="text-xs border border-[#E4E6E3] text-[#2F2F2F]/60 px-2 py-0.5 rounded-full"
                  >
                    {WorthAsking.Categories.label(cat)}
                  </span>
                </div>

                <%!-- Pause reason if paused --%>
                <%= if profile.paused && profile.paused_reason do %>
                  <p class="text-xs text-red-600 mt-2">
                    Reason: {profile.paused_reason}
                  </p>
                <% end %>
              </div>

              <%!-- Right: actions --%>
              <div class="shrink-0">
                <%= if profile.paused do %>
                  <button
                    phx-click="unpause"
                    phx-value-profile-id={profile.id}
                    class="px-3 py-1.5 text-xs font-medium border border-[#A8BDA4] text-[#6F8F6B] rounded-md hover:bg-[#A8BDA4]/10 transition-colors"
                  >
                    Unpause
                  </button>
                <% else %>
                  <button
                    phx-click="show_pause_modal"
                    phx-value-profile-id={profile.id}
                    class="px-3 py-1.5 text-xs font-medium border border-[#E4E6E3] text-[#2F2F2F]/50 rounded-md hover:border-red-300 hover:text-red-600 transition-colors"
                  >
                    Pause
                  </button>
                <% end %>
              </div>
            </div>
          </div>
        </div>
      <% end %>

      <%!-- Pause confirmation modal --%>
      <%= if @pause_modal do %>
        <div class="fixed inset-0 bg-black/30 flex items-center justify-center z-50" phx-click="cancel_pause">
          <div class="bg-white rounded-lg p-6 max-w-md w-full mx-4 shadow-lg" phx-click-away="cancel_pause">
            <h3 class="text-lg font-semibold text-[#2F2F2F] mb-1" style="font-family: Georgia, serif;">
              Pause Contributor
            </h3>
            <p class="text-sm text-[#2F2F2F]/50 mb-4">
              This will set them offline and prevent them from receiving new questions.
            </p>

            <.form for={%{}} phx-submit="confirm_pause" class="space-y-4">
              <div>
                <label class="text-sm font-medium text-[#2F2F2F] mb-1 block">Reason (optional)</label>
                <textarea
                  name="reason"
                  rows="3"
                  placeholder="e.g. Quality concerns, extended absence..."
                  class="w-full border border-[#E4E6E3] rounded-lg p-3 text-sm resize-none focus:outline-none focus:border-[#6F8F9D] focus:ring-1 focus:ring-[#6F8F9D]"
                >{@pause_reason}</textarea>
              </div>

              <div class="flex gap-3 justify-end">
                <button
                  type="button"
                  phx-click="cancel_pause"
                  class="px-4 py-2 text-sm border border-[#E4E6E3] rounded-md text-[#2F2F2F]/70 hover:bg-[#F7F7F5] transition-colors"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  class="px-4 py-2 text-sm bg-red-600 text-white rounded-md hover:bg-red-700 transition-colors"
                >
                  Pause Contributor
                </button>
              </div>
            </.form>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  @impl true
  def handle_event("show_pause_modal", %{"profile-id" => profile_id}, socket) do
    {:noreply, assign(socket, pause_modal: profile_id, pause_reason: "")}
  end

  @impl true
  def handle_event("cancel_pause", _params, socket) do
    {:noreply, assign(socket, pause_modal: nil, pause_reason: "")}
  end

  @impl true
  def handle_event("confirm_pause", %{"reason" => reason}, socket) do
    profile_id = socket.assigns.pause_modal
    profile = Enum.find(socket.assigns.contributors, &(&1.id == profile_id))

    reason = if String.trim(reason) == "", do: nil, else: String.trim(reason)

    case Contributors.pause_contributor(profile, reason) do
      {:ok, _profile} ->
        contributors = Contributors.list_approved_contributors()

        {:noreply,
         socket
         |> assign(:contributors, contributors)
         |> assign(:pause_modal, nil)
         |> assign(:pause_reason, "")
         |> put_flash(:info, "#{profile.display_name} has been paused.")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to pause contributor.")}
    end
  end

  @impl true
  def handle_event("unpause", %{"profile-id" => profile_id}, socket) do
    profile = Enum.find(socket.assigns.contributors, &(&1.id == profile_id))

    case Contributors.unpause_contributor(profile) do
      {:ok, _profile} ->
        contributors = Contributors.list_approved_contributors()

        {:noreply,
         socket
         |> assign(:contributors, contributors)
         |> put_flash(:info, "#{profile.display_name} has been unpaused.")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to unpause contributor.")}
    end
  end

  defp format_cents(nil), do: "0.00"
  defp format_cents(cents) when is_integer(cents) do
    dollars = div(cents, 100)
    remainder = rem(cents, 100)
    "#{dollars}.#{String.pad_leading(Integer.to_string(remainder), 2, "0")}"
  end
end
