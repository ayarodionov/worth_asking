defmodule WorthAskingWeb.Components.ResponseCard do
  @moduledoc """
  Reusable response card component for displaying contributor perspectives.
  Completely isolated from layout logic.
  """
  use Phoenix.Component

  attr :response, :map, required: true
  attr :index, :integer, required: true
  attr :liked, :boolean, default: false
  attr :saved, :boolean, default: false
  attr :show_actions, :boolean, default: true

  def response_card(assigns) do
    ~H"""
    <div class="bg-white border border-[#E4E6E3] rounded-lg p-5 sm:p-6">
      <%!-- Contributor identity --%>
      <div class="flex items-center gap-3 mb-4">
        <div class="w-8 h-8 rounded-full bg-[#A8BDA4]/20 flex items-center justify-center flex-shrink-0">
          <span class="text-xs font-semibold text-[#6F8F6B]">{String.first(@response.alias_name || "?")}</span>
        </div>
        <div class="flex-1 min-w-0">
          <p class="text-sm font-medium text-[#2F2F2F]">{@response.alias_name || "Anonymous"}</p>
          <p :if={@response.age_range} class="text-xs text-[#2F2F2F]/40">{@response.age_range}</p>
        </div>
        <p class="text-xs text-[#2F2F2F]/30 flex-shrink-0">
          Perspective {@index}
        </p>
      </div>

      <%!-- Tone tag placeholder --%>
      <%!-- <span class="text-xs px-2 py-0.5 rounded-full bg-[#F7F7F5] text-[#2F2F2F]/40 mb-3 inline-block">Direct</span> --%>

      <%!-- Response text --%>
      <p class="text-sm text-[#2F2F2F]/80 leading-relaxed whitespace-pre-line">
        {@response.text}
      </p>

      <%!-- User interactions --%>
      <div :if={@show_actions} class="flex items-center gap-4 mt-5 pt-4 border-t border-[#E4E6E3]/60">
        <button
          phx-click="toggle_like"
          phx-value-response-id={@response.id}
          class={"flex items-center gap-1.5 text-xs transition-colors " <> if(@liked, do: "text-rose-500", else: "text-[#2F2F2F]/35 hover:text-rose-400")}
        >
          <span class="text-sm"><%= if @liked, do: "&#10084;&#65039;", else: "&#9825;" %></span>
          <span>This resonates</span>
        </button>
        <button
          phx-click="toggle_save"
          phx-value-response-id={@response.id}
          class={"flex items-center gap-1.5 text-xs transition-colors " <> if(@saved, do: "text-amber-500", else: "text-[#2F2F2F]/35 hover:text-amber-400")}
        >
          <span class="text-sm"><%= if @saved, do: "&#11088;", else: "&#9734;" %></span>
          <span>Save</span>
        </button>
        <%!-- Placeholder for future "Request clarification" --%>
        <%!-- <button class="text-xs text-[#2F2F2F]/25 ml-auto">Request clarification</button> --%>
      </div>
    </div>
    """
  end

  @doc "Placeholder card for a response that hasn't arrived yet."
  attr :index, :integer, required: true

  def response_card_placeholder(assigns) do
    ~H"""
    <div class="border border-dashed border-[#E4E6E3] rounded-lg p-5 sm:p-6">
      <div class="flex items-center gap-3 mb-4">
        <div class="w-8 h-8 rounded-full bg-[#E4E6E3]/40 flex items-center justify-center flex-shrink-0">
          <span class="text-xs text-[#2F2F2F]/20">?</span>
        </div>
        <div>
          <p class="text-sm text-[#2F2F2F]/20">Waiting...</p>
        </div>
        <p class="text-xs text-[#2F2F2F]/20 ml-auto">Perspective {@index}</p>
      </div>
      <div class="flex items-center gap-2 text-sm text-[#2F2F2F]/25">
        <div class="w-3 h-3 border-2 border-[#E4E6E3] border-t-transparent rounded-full animate-spin"></div>
        <span>Response on its way...</span>
      </div>
    </div>
    """
  end
end
