defmodule WorthAskingWeb.Admin.AdminDashboardLive do
  use WorthAskingWeb, :live_view

  alias WorthAsking.Moderation
  alias WorthAsking.Contributors

  @impl true
  def mount(_params, _session, socket) do
    pending_reports = Moderation.list_pending_reports() |> length()
    pending_applications = Contributors.list_pending_applications() |> length()
    approved_contributors = Contributors.list_approved_contributors()
    active_count = Enum.count(approved_contributors, & &1.available_now)
    paused_count = Enum.count(approved_contributors, & &1.paused)

    socket =
      socket
      |> assign(:page_title, "Admin Dashboard")
      |> assign(:pending_reports, pending_reports)
      |> assign(:pending_applications, pending_applications)
      |> assign(:contributor_count, length(approved_contributors))
      |> assign(:active_count, active_count)
      |> assign(:paused_count, paused_count)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-3xl mx-auto px-6 py-12">
      <h1 class="text-3xl font-semibold text-[#2F2F2F] mb-8" style="font-family: Georgia, serif;">
        Admin Dashboard
      </h1>

      <div class="grid grid-cols-1 sm:grid-cols-3 gap-6">
        <a
          href={~p"/admin/reports"}
          class="block border border-[#E4E6E3] rounded-lg p-6 bg-white hover:border-[#6F8F9D] transition-colors"
        >
          <p class="text-sm text-[#2F2F2F]/60 mb-1">Pending Reports</p>
          <p class="text-3xl font-semibold text-[#2F2F2F]" style="font-family: Georgia, serif;">
            {@pending_reports}
          </p>
          <p class="text-sm text-[#6F8F9D] mt-3">Review reports &rarr;</p>
        </a>

        <a
          href={~p"/admin/applications"}
          class="block border border-[#E4E6E3] rounded-lg p-6 bg-white hover:border-[#6F8F9D] transition-colors"
        >
          <p class="text-sm text-[#2F2F2F]/60 mb-1">Pending Applications</p>
          <p class="text-3xl font-semibold text-[#2F2F2F]" style="font-family: Georgia, serif;">
            {@pending_applications}
          </p>
          <p class="text-sm text-[#6F8F9D] mt-3">Review applications &rarr;</p>
        </a>

        <a
          href={~p"/admin/contributors"}
          class="block border border-[#E4E6E3] rounded-lg p-6 bg-white hover:border-[#6F8F9D] transition-colors"
        >
          <p class="text-sm text-[#2F2F2F]/60 mb-1">Contributors</p>
          <p class="text-3xl font-semibold text-[#2F2F2F]" style="font-family: Georgia, serif;">
            {@contributor_count}
          </p>
          <p class="text-xs text-[#2F2F2F]/40 mt-1">
            {if @active_count > 0, do: "#{@active_count} online", else: "none online"}
            {if @paused_count > 0, do: " · #{@paused_count} paused", else: ""}
          </p>
          <p class="text-sm text-[#6F8F9D] mt-2">Manage contributors &rarr;</p>
        </a>
      </div>
    </div>
    """
  end
end
