defmodule WorthAskingWeb.AboutLive do
  use WorthAskingWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, "About")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-[640px] mx-auto px-6 py-14 lg:py-20">

      <%!-- Headline --%>
      <header class="mb-16">
        <p class="text-xs tracking-[0.2em] uppercase text-[#2F2F2F]/30 mb-4">About</p>
        <h1 class="text-3xl lg:text-4xl font-semibold tracking-tight leading-tight text-[#2F2F2F] mb-8" style="font-family: Georgia, serif;">
          Worth Asking
        </h1>
        <p class="text-lg text-[#2F2F2F]/80 leading-relaxed" style="font-family: Georgia, serif;">
          Worth Asking exists for one simple reason:<br />
          most men don't have a place to ask women honest questions&mdash;and get honest answers.
        </p>
      </header>

      <%!-- Opening hook --%>
      <div class="mb-16">
        <p class="text-[#2F2F2F]/60 leading-[1.8] mb-2">Not filtered through friends.</p>
        <p class="text-[#2F2F2F]/60 leading-[1.8] mb-2">Not shaped by ego.</p>
        <p class="text-[#2F2F2F]/60 leading-[1.8] mb-6">Not distorted by guesswork or internet noise.</p>
        <p class="text-[#2F2F2F]/80 leading-[1.8]" style="font-family: Georgia, serif;">Just real perspective.</p>
      </div>

      <div class="w-12 border-t border-[#E4E6E3] mb-16"></div>

      <%!-- Why This Exists --%>
      <section class="mb-16">
        <h2 class="text-xs tracking-[0.2em] uppercase text-[#2F2F2F]/30 mb-6">Why This Exists</h2>

        <p class="text-[#2F2F2F]/70 leading-[1.8] mb-4" style="font-family: Georgia, serif;">
          From an early age, women are taught how to move through the world in relation to others&mdash;how to communicate, present themselves, read situations, and respond.
        </p>
        <p class="text-[#2F2F2F]/70 leading-[1.8] mb-6" style="font-family: Georgia, serif;">
          Men are rarely given that same kind of guidance.
        </p>
        <p class="text-[#2F2F2F]/50 leading-[1.8] mb-1">So what happens?</p>
        <div class="pl-4 border-l-2 border-[#E4E6E3] mb-6 space-y-1">
          <p class="text-[#2F2F2F]/60 leading-[1.8]">They guess.</p>
          <p class="text-[#2F2F2F]/60 leading-[1.8]">They ask other men.</p>
          <p class="text-[#2F2F2F]/60 leading-[1.8]">Or they turn to loud corners of the internet that reward confidence over accuracy.</p>
        </div>
        <p class="text-[#2F2F2F]/70 leading-[1.8] mb-4" style="font-family: Georgia, serif;">
          That gap creates frustration on both sides.
        </p>
        <p class="text-[#2F2F2F]/80 leading-[1.8]" style="font-family: Georgia, serif;">
          Worth Asking is built to close it.
        </p>
      </section>

      <div class="w-12 border-t border-[#E4E6E3] mb-16"></div>

      <%!-- What This Is --%>
      <section class="mb-16">
        <h2 class="text-xs tracking-[0.2em] uppercase text-[#2F2F2F]/30 mb-6">What This Is (and What It's Not)</h2>

        <div class="space-y-1 mb-6">
          <p class="text-[#2F2F2F]/50 leading-[1.8]">This is not therapy.</p>
          <p class="text-[#2F2F2F]/50 leading-[1.8]">This is not a debate forum.</p>
          <p class="text-[#2F2F2F]/50 leading-[1.8]">This is not a place for posturing or proving a point.</p>
        </div>

        <p class="text-[#2F2F2F]/80 leading-[1.8] mb-6" style="font-family: Georgia, serif;">
          This is a direct line to perspective you don't otherwise have.
        </p>

        <div class="space-y-1 mb-6">
          <p class="text-[#2F2F2F]/60 leading-[1.8]">You ask a question.</p>
          <p class="text-[#2F2F2F]/60 leading-[1.8]">Women respond&mdash;clearly, honestly, and without social pressure.</p>
        </div>

        <div class="space-y-1">
          <p class="text-[#2F2F2F]/50 leading-[1.8]">No consequences.</p>
          <p class="text-[#2F2F2F]/50 leading-[1.8]">No awkwardness.</p>
          <p class="text-[#2F2F2F]/50 leading-[1.8]">No fallout in your real life.</p>
        </div>
      </section>

      <div class="w-12 border-t border-[#E4E6E3] mb-16"></div>

      <%!-- Why It Works --%>
      <section class="mb-16">
        <h2 class="text-xs tracking-[0.2em] uppercase text-[#2F2F2F]/30 mb-6">Why It Works</h2>

        <p class="text-[#2F2F2F]/80 leading-[1.8] mb-6" style="font-family: Georgia, serif;">
          People are more honest when there's nothing at stake.
        </p>

        <div class="space-y-1 mb-6">
          <p class="text-[#2F2F2F]/50 leading-[1.8]">No reputation to protect.</p>
          <p class="text-[#2F2F2F]/50 leading-[1.8]">No relationship to manage.</p>
          <p class="text-[#2F2F2F]/50 leading-[1.8]">No need to soften the truth.</p>
        </div>

        <p class="text-[#2F2F2F]/70 leading-[1.8]" style="font-family: Georgia, serif;">
          That's what makes the answers here useful.
        </p>
      </section>

      <div class="w-12 border-t border-[#E4E6E3] mb-16"></div>

      <%!-- What We're Trying to Fix --%>
      <section class="mb-16">
        <h2 class="text-xs tracking-[0.2em] uppercase text-[#2F2F2F]/30 mb-6">What We're Solving</h2>

        <p class="text-[#2F2F2F]/70 leading-[1.8] mb-6" style="font-family: Georgia, serif;">
          A lot of modern advice directed at men is built on assumptions about women&mdash;not input from them.
        </p>

        <p class="text-[#2F2F2F]/50 leading-[1.8] mb-2">That disconnect leads to:</p>
        <div class="pl-4 border-l-2 border-[#E4E6E3] mb-6 space-y-1">
          <p class="text-[#2F2F2F]/60 leading-[1.8]">Confusion</p>
          <p class="text-[#2F2F2F]/60 leading-[1.8]">Frustration</p>
          <p class="text-[#2F2F2F]/60 leading-[1.8]">Resentment</p>
          <p class="text-[#2F2F2F]/60 leading-[1.8]">And ultimately, failure in the very relationships men are trying to build</p>
        </div>

        <p class="text-[#2F2F2F]/60 leading-[1.8] mb-1">We're not here to shame that.</p>
        <p class="text-[#2F2F2F]/70 leading-[1.8] mb-6" style="font-family: Georgia, serif;">We're here to replace it with something better.</p>

        <p class="text-[#2F2F2F]/80 leading-[1.8]" style="font-family: Georgia, serif;">
          Real answers from real women.
        </p>
      </section>

      <div class="w-12 border-t border-[#E4E6E3] mb-16"></div>

      <%!-- The Standard --%>
      <section class="mb-16">
        <h2 class="text-xs tracking-[0.2em] uppercase text-[#2F2F2F]/30 mb-6">The Standard</h2>

        <p class="text-[#2F2F2F]/80 leading-[1.8] mb-6" style="font-family: Georgia, serif;">
          Respect goes both ways.
        </p>

        <div class="space-y-1 mb-6">
          <p class="text-[#2F2F2F]/60 leading-[1.8]">Men ask with curiosity, not hostility.</p>
          <p class="text-[#2F2F2F]/60 leading-[1.8]">Women answer with honesty, not condescension.</p>
        </div>

        <div class="space-y-1 mb-6">
          <p class="text-[#2F2F2F]/50 leading-[1.8]">No one is here to perform.</p>
          <p class="text-[#2F2F2F]/50 leading-[1.8]">No one is here to be managed.</p>
        </div>

        <p class="text-[#2F2F2F]/80 leading-[1.8]" style="font-family: Georgia, serif;">Just clarity.</p>
      </section>

      <div class="w-12 border-t border-[#E4E6E3] mb-16"></div>

      <%!-- Closing --%>
      <section class="mb-16">
        <h2 class="text-xs tracking-[0.2em] uppercase text-[#2F2F2F]/30 mb-6">The Bottom Line</h2>

        <p class="text-[#2F2F2F]/50 leading-[1.8] mb-1">If you've ever thought:</p>
        <div class="pl-4 border-l-2 border-[#A8BDA4]/40 mb-8 space-y-2 py-1">
          <p class="text-[#2F2F2F]/70 leading-[1.8]" style="font-family: Georgia, serif;">"I wish I could ask this without it being weird"</p>
          <p class="text-[#2F2F2F]/70 leading-[1.8]" style="font-family: Georgia, serif;">"I don't want to get this wrong again"</p>
          <p class="text-[#2F2F2F]/70 leading-[1.8]" style="font-family: Georgia, serif;">"I just want to understand"</p>
        </div>

        <p class="text-[#2F2F2F]/70 leading-[1.8] mb-6">You're in the right place.</p>

        <p class="text-[#2F2F2F]/60 leading-[1.8] mb-2">Because some questions are too important to guess.</p>
        <p class="text-lg text-[#2F2F2F] leading-[1.8]" style="font-family: Georgia, serif;">
          They're worth asking.
        </p>
      </section>

      <%!-- CTA --%>
      <div class="pt-8 border-t border-[#E4E6E3]">
        <a
          href={~p"/questions/new"}
          class="inline-block text-sm text-[#6F8F9D] hover:text-[#5a7a87] transition-colors"
          style="font-family: Georgia, serif;"
        >
          Ask your first question &rarr;
        </a>
      </div>
    </div>
    """
  end
end
