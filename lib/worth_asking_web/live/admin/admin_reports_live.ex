defmodule WorthAskingWeb.Admin.AdminReportsLive do
  use WorthAskingWeb, :live_view

  alias WorthAsking.Moderation

  @impl true
  def mount(_params, _session, socket) do
    reports = Moderation.list_pending_reports()

    socket =
      socket
      |> assign(:page_title, "Pending Reports")
      |> assign(:reports, reports)
      |> assign(:admin_notes, %{})

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
        Pending Reports
      </h1>

      <%= if @reports == [] do %>
        <div class="border border-[#E4E6E3] rounded-lg p-8 text-center bg-white">
          <p class="text-[#2F2F2F]/60">No pending reports.</p>
        </div>
      <% else %>
        <div class="space-y-4">
          <div
            :for={report <- @reports}
            class="border border-[#E4E6E3] rounded-lg p-6 bg-white"
          >
            <div class="grid grid-cols-2 gap-4 mb-4">
              <div>
                <p class="text-xs text-[#2F2F2F]/50 uppercase tracking-wide mb-1">Reporter</p>
                <p class="text-sm text-[#2F2F2F]">{report.reporter.email}</p>
              </div>
              <div>
                <p class="text-xs text-[#2F2F2F]/50 uppercase tracking-wide mb-1">Reported User</p>
                <p class="text-sm text-[#2F2F2F]">{report.reported_user.email}</p>
              </div>
              <div>
                <p class="text-xs text-[#2F2F2F]/50 uppercase tracking-wide mb-1">Reason</p>
                <p class="text-sm text-[#2F2F2F]">
                  {report.reason |> to_string() |> String.replace("_", " ") |> String.capitalize()}
                </p>
              </div>
              <div>
                <p class="text-xs text-[#2F2F2F]/50 uppercase tracking-wide mb-1">Content Type</p>
                <p class="text-sm text-[#2F2F2F]">{report.reported_content_type}</p>
              </div>
            </div>

            <%= if report.description do %>
              <div class="mb-4">
                <p class="text-xs text-[#2F2F2F]/50 uppercase tracking-wide mb-1">Description</p>
                <p class="text-sm text-[#2F2F2F]">{report.description}</p>
              </div>
            <% end %>

            <div class="mb-4">
              <label class="text-xs text-[#2F2F2F]/50 uppercase tracking-wide mb-1 block">
                Admin Notes
              </label>
              <textarea
                phx-blur="update_notes"
                phx-value-report-id={report.id}
                rows="2"
                placeholder="Add notes (optional)..."
                class="w-full border border-[#E4E6E3] rounded-md p-2 text-sm resize-none focus:outline-none focus:border-[#6F8F9D] focus:ring-1 focus:ring-[#6F8F9D] bg-white"
              >{Map.get(@admin_notes, report.id, "")}</textarea>
            </div>

            <div class="flex gap-3">
              <button
                phx-click="resolve"
                phx-value-report-id={report.id}
                class="px-4 py-2 bg-[#6F8F9D] text-white text-sm rounded-md hover:bg-[#5a7a87] transition-colors"
              >
                Resolve
              </button>
              <button
                phx-click="dismiss"
                phx-value-report-id={report.id}
                class="px-4 py-2 border border-[#E4E6E3] text-[#2F2F2F]/70 text-sm rounded-md hover:border-[#6F8F9D] transition-colors"
              >
                Dismiss
              </button>
            </div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  @impl true
  def handle_event("update_notes", %{"report-id" => report_id, "value" => value}, socket) do
    admin_notes = Map.put(socket.assigns.admin_notes, report_id, value)
    {:noreply, assign(socket, :admin_notes, admin_notes)}
  end

  @impl true
  def handle_event("resolve", %{"report-id" => report_id}, socket) do
    report = Enum.find(socket.assigns.reports, &(&1.id == report_id))
    notes = Map.get(socket.assigns.admin_notes, report_id, "")

    case Moderation.resolve_report(report, %{status: :resolved, admin_notes: notes}) do
      {:ok, _report} ->
        reports = Moderation.list_pending_reports()
        {:noreply, assign(socket, :reports, reports)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to resolve report.")}
    end
  end

  @impl true
  def handle_event("dismiss", %{"report-id" => report_id}, socket) do
    report = Enum.find(socket.assigns.reports, &(&1.id == report_id))

    case Moderation.resolve_report(report, %{status: :dismissed}) do
      {:ok, _report} ->
        reports = Moderation.list_pending_reports()
        {:noreply, assign(socket, :reports, reports)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to dismiss report.")}
    end
  end
end
