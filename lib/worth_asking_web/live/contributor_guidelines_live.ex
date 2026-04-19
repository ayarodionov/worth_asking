defmodule WorthAskingWeb.ContributorGuidelinesLive do
  use WorthAskingWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, "Contributor Guidelines")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto px-6 py-12 lg:py-16">
      <%!-- Progress indicator --%>
      <div class="flex items-center gap-3 mb-10">
        <div class="flex items-center gap-2">
          <div class="w-7 h-7 rounded-full bg-[#6F8F6B] flex items-center justify-center">
            <svg class="w-3.5 h-3.5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M5 13l4 4L19 7"/>
            </svg>
          </div>
          <span class="text-sm text-[#6F8F6B]">Profile Setup</span>
        </div>
        <div class="flex-1 h-px bg-[#6F8F6B]"></div>
        <div class="flex items-center gap-2">
          <div class="w-7 h-7 rounded-full bg-[#6F8F6B] flex items-center justify-center">
            <span class="text-xs font-semibold text-white">2</span>
          </div>
          <span class="text-sm font-medium text-[#2F2F2F]">Guidelines</span>
        </div>
      </div>

      <%!-- Header --%>
      <header class="mb-10">
        <h1 class="text-2xl lg:text-3xl font-semibold tracking-tight text-[#2F2F2F] mb-3" style="font-family: Georgia, serif;">
          How to Respond
        </h1>
        <p class="text-[#2F2F2F]/60 leading-relaxed">
          A quick overview of what makes a strong response on Worth Asking.
        </p>
      </header>

      <%!-- Guidelines --%>
      <div class="space-y-8">
        <section class="bg-white border border-[#E4E6E3] rounded-lg p-6 lg:p-8">
          <h2 class="text-xs tracking-[0.2em] uppercase text-[#2F2F2F]/30 mb-5">Tone</h2>
          <div class="space-y-3">
            <p class="text-sm text-[#2F2F2F]/70 leading-relaxed">Be direct, but not harsh.</p>
            <p class="text-sm text-[#2F2F2F]/70 leading-relaxed">Be helpful, not performative.</p>
            <p class="text-sm text-[#2F2F2F]/70 leading-relaxed">Answer as if you're speaking to someone who genuinely wants to understand.</p>
          </div>
        </section>

        <section class="bg-white border border-[#E4E6E3] rounded-lg p-6 lg:p-8">
          <h2 class="text-xs tracking-[0.2em] uppercase text-[#2F2F2F]/30 mb-5">What to Avoid</h2>
          <div class="space-y-3">
            <p class="text-sm text-[#2F2F2F]/70 leading-relaxed">Don't over-explain or "teach a lesson." Keep it grounded and real.</p>
            <p class="text-sm text-[#2F2F2F]/70 leading-relaxed">Don't speak as a universal authority. Speak from your perspective.</p>
            <p class="text-sm text-[#2F2F2F]/70 leading-relaxed">Avoid sarcasm, condescension, or dismissiveness.</p>
          </div>
        </section>

        <section class="bg-white border border-[#E4E6E3] rounded-lg p-6 lg:p-8">
          <h2 class="text-xs tracking-[0.2em] uppercase text-[#2F2F2F]/30 mb-5">Quality Standards</h2>
          <div class="space-y-3">
            <p class="text-sm text-[#2F2F2F]/70 leading-relaxed">Responses should be thoughtful and substantive &mdash; a few sentences to a few paragraphs.</p>
            <p class="text-sm text-[#2F2F2F]/70 leading-relaxed">Answer the question that was actually asked, not the one you wish was asked.</p>
            <p class="text-sm text-[#2F2F2F]/70 leading-relaxed">If a question isn't a good fit for you, skip it. There's no obligation to answer every question.</p>
          </div>
        </section>

        <section class="bg-white border border-[#E4E6E3] rounded-lg p-6 lg:p-8">
          <h2 class="text-xs tracking-[0.2em] uppercase text-[#2F2F2F]/30 mb-5">Boundaries</h2>
          <div class="space-y-3">
            <p class="text-sm text-[#2F2F2F]/70 leading-relaxed">You remain anonymous. Users do not see your real identity.</p>
            <p class="text-sm text-[#2F2F2F]/70 leading-relaxed">There is no direct messaging or ongoing conversations.</p>
            <p class="text-sm text-[#2F2F2F]/70 leading-relaxed">All questions are screened before they reach you. Content moderation is in place.</p>
            <p class="text-sm text-[#2F2F2F]/70 leading-relaxed">You can skip any question, for any reason, at any time.</p>
          </div>
        </section>
      </div>

      <%!-- CTA --%>
      <div class="mt-10">
        <a
          href={~p"/dashboard"}
          class="block w-full py-3 bg-[#6F8F6B] text-white text-sm font-medium rounded-lg hover:bg-[#5a7a57] transition-colors text-center"
        >
          Go to Your Dashboard
        </a>
        <p class="text-xs text-center text-[#2F2F2F]/30 mt-3">
          You're all set. Questions will start coming in based on your availability.
        </p>
      </div>
    </div>
    """
  end
end
