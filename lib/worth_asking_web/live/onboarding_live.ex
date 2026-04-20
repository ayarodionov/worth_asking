defmodule WorthAskingWeb.OnboardingLive do
  use WorthAskingWeb, :live_view

  @total_steps 8

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Worth Asking")
     |> assign(:step, 1)
     |> assign(:total_steps, @total_steps)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-[#F7F7F5] flex flex-col">
      <%!-- Progress dots --%>
      <div class="flex justify-center gap-2 pt-8 pb-4">
        <div
          :for={s <- 1..@total_steps}
          class={[
            "w-1.5 h-1.5 rounded-full transition-colors",
            if(s == @step, do: "bg-[#2F2F2F]", else: "bg-[#2F2F2F]/15")
          ]}
        />
      </div>

      <%!-- Content area --%>
      <div class="flex-1 flex items-center justify-center px-6">
        <div class="max-w-md w-full text-center">

          <%!-- Step 1: Intro --%>
          <%= if @step == 1 do %>
            <h1 class="text-4xl font-semibold tracking-tight mb-3" style="font-family: Georgia, serif;">
              Worth Asking
            </h1>
            <p class="text-sm text-[#2F2F2F]/50 mb-12">Get a second perspective</p>
            <p class="text-[#2F2F2F]/70 leading-relaxed mb-2">Ask a real question.</p>
            <p class="text-[#2F2F2F]/70 leading-relaxed">Get thoughtful responses.</p>
          <% end %>

          <%!-- Step 2: What this is --%>
          <%= if @step == 2 do %>
            <p class="text-lg text-[#2F2F2F] leading-relaxed mb-6" style="font-family: Georgia, serif;">
              Sometimes you don't need advice.
              <br />You need perspective.
            </p>
            <p class="text-[#2F2F2F]/60 leading-relaxed">
              We connect your question with people who can help you see it more clearly.
            </p>
          <% end %>

          <%!-- Step 3: How it works --%>
          <%= if @step == 3 do %>
            <p class="text-lg text-[#2F2F2F] leading-relaxed mb-6" style="font-family: Georgia, serif;">
              You ask one question.
              <br />You receive three perspectives.
            </p>
            <p class="text-[#2F2F2F]/60 leading-relaxed">
              Each response is thoughtful, direct, and grounded.
            </p>
          <% end %>

          <%!-- Step 4: What you can ask --%>
          <%= if @step == 4 do %>
            <div class="space-y-4 mb-8">
              <div class="bg-white border border-[#E4E6E3] rounded-lg px-5 py-4 text-left">
                <p class="text-sm text-[#2F2F2F]/80">"Should I text her again?"</p>
              </div>
              <div class="bg-white border border-[#E4E6E3] rounded-lg px-5 py-4 text-left">
                <p class="text-sm text-[#2F2F2F]/80">"Did I come off too strong?"</p>
              </div>
              <div class="bg-white border border-[#E4E6E3] rounded-lg px-5 py-4 text-left">
                <p class="text-sm text-[#2F2F2F]/80">"What should I wear on this date?"</p>
              </div>
              <div class="bg-white border border-[#E4E6E3] rounded-lg px-5 py-4 text-left">
                <p class="text-sm text-[#2F2F2F]/80">"How do I bring up exclusivity?"</p>
              </div>
            </div>
            <p class="text-[#2F2F2F]/60 text-sm leading-relaxed">
              Ask about real situations&mdash;no pressure, no judgment.
            </p>
          <% end %>

          <%!-- Step 5: Session types --%>
          <%= if @step == 5 do %>
            <p class="text-sm text-[#2F2F2F]/50 uppercase tracking-wider mb-6">Choose your format</p>
            <div class="space-y-4 text-left">
              <div class="bg-white border border-[#E4E6E3] rounded-lg p-6">
                <p class="text-sm font-medium text-[#2F2F2F] mb-2">Basic</p>
                <p class="text-sm text-[#2F2F2F]/60 leading-relaxed">
                  3 perspectives. Quick, clear, and to the point.
                </p>
              </div>
              <div class="bg-white border border-[#6F8F9D] rounded-lg p-6">
                <p class="text-sm font-medium text-[#2F2F2F] mb-2">Interactive</p>
                <p class="text-sm text-[#2F2F2F]/60 leading-relaxed">
                  Refine your question. Add context. Ask follow-ups.
                </p>
              </div>
            </div>
          <% end %>

          <%!-- Step 6: Who responds --%>
          <%= if @step == 6 do %>
            <p class="text-lg text-[#2F2F2F] leading-relaxed mb-6" style="font-family: Georgia, serif;">
              Real people. Vetted perspectives.
            </p>
            <p class="text-[#2F2F2F]/60 leading-relaxed mb-2">
              Every contributor is reviewed before they can respond.
            </p>
            <p class="text-[#2F2F2F]/60 leading-relaxed">
              No bots. No recycled content. Just honest perspective from women who've been through it.
            </p>
          <% end %>

          <%!-- Step 7: What to expect --%>
          <%= if @step == 7 do %>
            <p class="text-lg text-[#2F2F2F] mb-6" style="font-family: Georgia, serif;">
              What to expect
            </p>
            <div class="space-y-4 text-left">
              <div class="flex items-start gap-4">
                <div class="w-7 h-7 rounded-full bg-[#A8BDA4]/20 flex items-center justify-center flex-shrink-0 mt-0.5">
                  <span class="text-xs font-semibold text-[#6F8F6B]">1</span>
                </div>
                <p class="text-sm text-[#2F2F2F]/70">Write your question with as much or as little detail as you want</p>
              </div>
              <div class="flex items-start gap-4">
                <div class="w-7 h-7 rounded-full bg-[#A8BDA4]/20 flex items-center justify-center flex-shrink-0 mt-0.5">
                  <span class="text-xs font-semibold text-[#6F8F6B]">2</span>
                </div>
                <p class="text-sm text-[#2F2F2F]/70">Your question is sent to vetted contributors in the relevant category</p>
              </div>
              <div class="flex items-start gap-4">
                <div class="w-7 h-7 rounded-full bg-[#A8BDA4]/20 flex items-center justify-center flex-shrink-0 mt-0.5">
                  <span class="text-xs font-semibold text-[#6F8F6B]">3</span>
                </div>
                <p class="text-sm text-[#2F2F2F]/70">You receive 3 thoughtful perspectives, usually within a few hours</p>
              </div>
            </div>
          <% end %>

          <%!-- Step 8: Ready --%>
          <%= if @step == 8 do %>
            <p class="text-lg text-[#2F2F2F] mb-3" style="font-family: Georgia, serif;">
              You're ready.
            </p>
            <p class="text-[#2F2F2F]/60 leading-relaxed mb-8">
              Ask something real. Get clarity.
            </p>
            <a
              href={~p"/questions/new"}
              class="inline-block bg-[#6F8F9D] text-white px-8 py-3 rounded-lg text-sm font-medium hover:bg-[#5a7a87] transition-colors"
            >
              Ask your first question
            </a>
            <p class="mt-6">
              <a href={~p"/"} class="text-xs text-[#2F2F2F]/40 hover:underline">
                or browse the home page
              </a>
            </p>
          <% end %>
        </div>
      </div>

      <%!-- Navigation --%>
      <div class="px-6 pb-12 pt-8 max-w-md mx-auto w-full">
        <%= if @step < @total_steps do %>
          <button
            phx-click="next"
            class="w-full py-3 rounded-lg text-sm font-medium bg-[#6F8F9D] text-white hover:bg-[#5a7a87] transition-colors"
          >
            Continue
          </button>
        <% end %>
        <div class="flex justify-between mt-4">
          <button
            :if={@step > 1}
            phx-click="prev"
            class="text-sm text-[#2F2F2F]/40 hover:text-[#2F2F2F]/60 transition-colors"
          >
            Back
          </button>
          <span :if={@step == 1}></span>
          <a
            :if={@step < @total_steps}
            href={~p"/questions/new"}
            class="text-sm text-[#2F2F2F]/40 hover:text-[#2F2F2F]/60 transition-colors"
          >
            Skip
          </a>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("next", _params, socket) do
    {:noreply, assign(socket, :step, min(socket.assigns.step + 1, @total_steps))}
  end

  @impl true
  def handle_event("prev", _params, socket) do
    {:noreply, assign(socket, :step, max(socket.assigns.step - 1, 1))}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end
end
