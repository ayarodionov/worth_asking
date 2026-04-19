defmodule WorthAskingWeb.ContributorProfileLive do
  use WorthAskingWeb, :live_view

  alias WorthAsking.Repo
  alias WorthAsking.Contributors.Profile

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    profile = Repo.get!(Profile, id)

    socket =
      socket
      |> assign(:page_title, profile.display_name)
      |> assign(:profile, profile)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-xl mx-auto px-6 py-12" style="background-color: #F7F7F5; min-height: 100vh;">
      <a href={~p"/"} class="text-sm text-[#6F8F9D] hover:underline mb-8 inline-block">
        &larr; Back
      </a>

      <div class="bg-white border border-[#E4E6E3] rounded-lg p-8">
        <%!-- Header --%>
        <div class="mb-6">
          <div class="w-16 h-16 rounded-full bg-[#6F8F9D]/10 flex items-center justify-center mb-4">
            <span class="text-2xl font-semibold text-[#6F8F9D]">
              {@profile.display_name |> String.first() |> String.upcase()}
            </span>
          </div>
          <h1 class="text-2xl font-semibold text-[#2F2F2F]" style="font-family: Georgia, serif;">
            {@profile.display_name}
          </h1>
        </div>

        <%!-- Bio --%>
        <%= if @profile.bio && @profile.bio != "" do %>
          <div class="mb-6">
            <h2 class="text-xs font-medium text-[#2F2F2F]/50 uppercase tracking-wider mb-2">About</h2>
            <p class="text-sm text-[#2F2F2F]/80 leading-relaxed">{@profile.bio}</p>
          </div>
        <% end %>

        <%!-- Categories --%>
        <div class="mb-6">
          <h2 class="text-xs font-medium text-[#2F2F2F]/50 uppercase tracking-wider mb-3">Categories</h2>
          <div class="flex flex-wrap gap-2">
            <span
              :for={cat <- @profile.categories}
              class="text-xs font-medium px-3 py-1.5 rounded-full bg-[#A8BDA4]/20 text-[#6F8F6B]"
            >
              {cat |> to_string() |> String.replace("_", " ") |> String.split(" ") |> Enum.map(&String.capitalize/1) |> Enum.join(" ")}
            </span>
          </div>
        </div>

        <%!-- Stats --%>
        <div class="border-t border-[#E4E6E3] pt-6">
          <div class="grid grid-cols-2 gap-6">
            <%!-- Rating --%>
            <div>
              <h2 class="text-xs font-medium text-[#2F2F2F]/50 uppercase tracking-wider mb-2">Rating</h2>
              <div class="flex items-center gap-1">
                <span :for={star <- 1..5} class={[
                  "text-lg",
                  if(star <= round_rating(@profile.average_rating),
                    do: "text-[#6F8F9D]",
                    else: "text-[#E4E6E3]"
                  )
                ]}>
                  &#9733;
                </span>
                <span class="text-sm text-[#2F2F2F]/50 ml-1">
                  {format_rating(@profile.average_rating)}
                </span>
              </div>
            </div>

            <%!-- Response count --%>
            <div>
              <h2 class="text-xs font-medium text-[#2F2F2F]/50 uppercase tracking-wider mb-2">Responses</h2>
              <p class="text-xl font-semibold text-[#2F2F2F]">
                {@profile.response_count || 0}
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp round_rating(nil), do: 0
  defp round_rating(rating) when is_float(rating), do: round(rating)
  defp round_rating(rating) when is_integer(rating), do: rating

  defp format_rating(nil), do: "No ratings"
  defp format_rating(rating), do: :erlang.float_to_binary(rating * 1.0, decimals: 1)
end
