defmodule WorthAskingWeb.FieldNotesLive do
  use WorthAskingWeb, :live_view

  alias WorthAsking.FieldNotes

  @impl true
  def mount(_params, _session, socket) do
    notes = FieldNotes.list()
    tags = FieldNotes.all_tags()

    {:ok,
     socket
     |> assign(:page_title, "Field Notes")
     |> assign(:notes, notes)
     |> assign(:all_tags, tags)
     |> assign(:active_tag, nil)}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    tag = params["tag"]
    notes = FieldNotes.list(tag)

    {:noreply,
     socket
     |> assign(:notes, notes)
     |> assign(:active_tag, tag)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-[680px] mx-auto px-6 py-14 lg:py-20">
      <%!-- Header --%>
      <header class="mb-12">
        <p class="text-xs tracking-[0.2em] uppercase text-[#2F2F2F]/40 mb-3">Worth Asking</p>
        <h1 class="text-4xl lg:text-5xl font-semibold tracking-tight text-[#2F2F2F] mb-4" style="font-family: Georgia, serif;">
          Field Notes
        </h1>
        <p class="text-[#2F2F2F]/50 leading-relaxed" style="font-family: Georgia, serif;">
          Short reads. Clear thinking. For situations that actually come up.
        </p>
      </header>

      <%!-- Tag filter --%>
      <nav class="flex flex-wrap gap-2 mb-10 pb-8 border-b border-[#E4E6E3]">
        <.link
          patch={~p"/field-notes"}
          class={[
            "px-3 py-1.5 rounded-full text-xs tracking-wide transition-colors",
            if(is_nil(@active_tag),
              do: "bg-[#2F2F2F] text-white",
              else: "text-[#2F2F2F]/50 hover:text-[#2F2F2F]")
          ]}
        >
          All
        </.link>
        <.link
          :for={tag <- @all_tags}
          patch={~p"/field-notes?tag=#{tag}"}
          class={[
            "px-3 py-1.5 rounded-full text-xs tracking-wide transition-colors",
            if(@active_tag == tag,
              do: "bg-[#2F2F2F] text-white",
              else: "text-[#2F2F2F]/50 hover:text-[#2F2F2F]")
          ]}
        >
          {tag}
        </.link>
      </nav>

      <%!-- Notes --%>
      <div class="space-y-0 divide-y divide-[#E4E6E3]">
        <.link
          :for={note <- @notes}
          navigate={~p"/field-notes/#{note.slug}"}
          class="block py-7 group first:pt-0"
        >
          <div class="flex items-start justify-between gap-6">
            <div class="flex-1 min-w-0">
              <h2 class="text-xl font-semibold text-[#2F2F2F] mb-2 group-hover:text-[#6F8F9D] transition-colors" style="font-family: Georgia, serif;">
                {note.title}
                <span :if={note.is_premium} class="inline-block ml-2 text-[10px] font-medium tracking-wide uppercase px-2 py-0.5 rounded bg-[#2F2F2F]/5 text-[#2F2F2F]/30 align-middle">
                  Members
                </span>
              </h2>
              <p class="text-sm text-[#2F2F2F]/50 leading-relaxed">
                {note.situation}
              </p>
            </div>
          </div>
          <div :if={note.tags != []} class="flex flex-wrap gap-1.5 mt-3">
            <span
              :for={tag <- note.tags}
              class="text-[10px] tracking-wide uppercase text-[#2F2F2F]/30"
            >
              {tag}
              <span :if={tag != List.last(note.tags)} class="ml-1.5">&middot;</span>
            </span>
          </div>
        </.link>
      </div>

      <%= if @notes == [] do %>
        <div class="text-center py-20">
          <p class="text-[#2F2F2F]/30" style="font-family: Georgia, serif;">Nothing here yet.</p>
        </div>
      <% end %>
    </div>
    """
  end
end
