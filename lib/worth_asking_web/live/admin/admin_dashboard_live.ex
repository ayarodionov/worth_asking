defmodule WorthAskingWeb.Admin.AdminDashboardLive do
  use WorthAskingWeb, :live_view

  alias WorthAsking.Moderation
  alias WorthAsking.Contributors

  @impl true
  def mount(_params, _session, socket) do
    pending_reports = Moderation.list_pending_reports() |> length()
    pending_applications = Contributors.list_pending_applications() |> length()

    socket =
      socket
      |> assign(:page_title, "Admin Dashboard")
      |> assign(:pending_reports, pending_reports)
      |> assign(:pending_applications, pending_applications)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-3xl mx-auto px-6 py-12">
      <h1 class="text-3xl font-semibold text-[#2F2F2F] mb-8" style="font-family: Georgia, serif;">
        Admin Dashboard
      </h1>

      <div class="grid grid-cols-1 sm:grid-cols-2 gap-6">
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
      </div>
    </div>
    """
  end
end
