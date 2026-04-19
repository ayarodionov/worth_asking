defmodule WorthAskingWeb.FieldNoteShowLive do
  use WorthAskingWeb, :live_view

  alias WorthAsking.FieldNotes

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    case FieldNotes.get_by_slug(slug) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "Field note not found.")
         |> redirect(to: ~p"/field-notes")}

      note ->
        user = get_current_user(socket)
        can_view = !note.is_premium || user != nil
        related = FieldNotes.related(slug)

        {:ok,
         socket
         |> assign(:page_title, note.title)
         |> assign(:note, note)
         |> assign(:can_view, can_view)
         |> assign(:related, related)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-[640px] mx-auto px-6 py-14 lg:py-20">
      <%!-- Back --%>
      <a href={~p"/field-notes"} class="inline-block text-xs tracking-[0.15em] uppercase text-[#2F2F2F]/30 hover:text-[#2F2F2F]/60 transition-colors mb-10">
        &larr; Field Notes
      </a>

      <%!-- Title --%>
      <h1 class="text-3xl lg:text-[2.5rem] font-semibold tracking-tight leading-tight text-[#2F2F2F] mb-6" style="font-family: Georgia, serif;">
        {@note.title}
      </h1>

      <%!-- Situation --%>
      <p class="text-[#2F2F2F]/50 leading-relaxed mb-10 text-[15px]">
        {@note.situation}
      </p>

      <div class="w-12 border-t border-[#E4E6E3] mb-10"></div>

      <%= if @can_view do %>
        <%!-- Insight --%>
        <div class="mb-10">
          <p
            :for={paragraph <- String.split(@note.insight, "\n\n")}
            class="text-[#2F2F2F]/80 leading-[1.8] mb-4 last:mb-0"
            style="font-family: Georgia, serif;"
          >
            {paragraph}
          </p>
        </div>

        <div class="w-12 border-t border-[#E4E6E3] mb-10"></div>

        <%!-- Quick Reference — visual anchor --%>
        <section class="mb-12">
          <p class="text-xs tracking-[0.2em] uppercase text-[#2F2F2F]/30 mb-5">
            Quick Reference
          </p>
          <ul class="space-y-3.5">
            <li
              :for={item <- @note.quick_reference}
              class="flex items-baseline gap-3 text-[15px] text-[#2F2F2F] leading-relaxed"
            >
              <span class="w-1.5 h-1.5 rounded-full bg-[#A8BDA4] shrink-0 mt-[0.45rem]"></span>
              {item}
            </li>
          </ul>
        </section>

        <div class="w-12 border-t border-[#E4E6E3] mb-10"></div>

        <%!-- Ask about this --%>
        <div class="mb-14">
          <a
            href={~p"/questions/new?q=#{@note.title}"}
            class="inline-block text-sm text-[#6F8F9D] hover:text-[#5a7a87] transition-colors"
            style="font-family: Georgia, serif;"
          >
            Ask about this situation &rarr;
          </a>
        </div>
      <% else %>
        <%!-- Premium gate --%>
        <div class="mb-14">
          <div class="relative py-8">
            <div class="text-[#2F2F2F]/10 leading-[1.8] text-[15px] select-none" style="font-family: Georgia, serif; filter: blur(5px);">
              This field note contains a focused insight and a quick reference checklist
              with clear, actionable steps for handling this exact situation. Create a free
              account to read the full note.
            </div>
            <div class="absolute inset-0 flex items-center justify-center">
              <div class="text-center">
                <p class="text-sm text-[#2F2F2F]/50 mb-4" style="font-family: Georgia, serif;">
                  Sign up to read this field note
                </p>
                <a
                  href={~p"/users/register"}
                  class="inline-block bg-[#2F2F2F] text-white px-6 py-2.5 rounded text-sm tracking-wide hover:bg-[#1a1a1a] transition-colors"
                >
                  Create an account
                </a>
              </div>
            </div>
          </div>
        </div>
      <% end %>

      <%!-- Related --%>
      <section :if={@related != [] && @can_view}>
        <p class="text-xs tracking-[0.2em] uppercase text-[#2F2F2F]/30 mb-5">
          Related situations
        </p>
        <div class="space-y-0 divide-y divide-[#E4E6E3]">
          <.link
            :for={related <- @related}
            navigate={~p"/field-notes/#{related.slug}"}
            class="block py-4 group first:pt-0"
          >
            <p class="text-sm text-[#2F2F2F] group-hover:text-[#6F8F9D] transition-colors" style="font-family: Georgia, serif;">
              {related.title}
            </p>
          </.link>
        </div>
      </section>
    </div>
    """
  end

  defp get_current_user(socket) do
    case socket.assigns do
      %{current_scope: %{user: user}} when not is_nil(user) -> user
      _ -> nil
    end
  end
end
