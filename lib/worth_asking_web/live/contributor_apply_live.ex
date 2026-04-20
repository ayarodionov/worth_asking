defmodule WorthAskingWeb.ContributorApplyLive do
  use WorthAskingWeb, :live_view

  alias WorthAsking.Contributors
  alias WorthAsking.Accounts.UserNotifier

  @categories [:communication, :first_impressions, :style, :dating_dynamics]

  # Scenario-based vetting questions — tests empathy, nuance, and communication quality
  @scenario_questions [
    %{
      id: :empathy_1,
      category: :communication,
      scenario:
        "A man writes: \"I told my girlfriend I love her and she just said 'thank you.' I feel humiliated. Was I wrong to say it?\"",
      prompt: "How would you respond to this person?",
      evaluates: "Empathy, emotional validation, and ability to reframe without dismissing feelings"
    },
    %{
      id: :nuance_1,
      category: :dating_dynamics,
      scenario:
        "A man writes: \"She takes 6-8 hours to respond to my texts but when we're together everything seems great. Should I bring this up?\"",
      prompt: "What would you tell him?",
      evaluates: "Nuance, avoiding assumptions, and balanced perspective"
    },
    %{
      id: :boundaries_1,
      category: :first_impressions,
      scenario:
        "A man writes: \"I keep getting told I'm 'too nice.' I open doors, pay for everything, compliment her constantly. What am I doing wrong?\"",
      prompt: "How would you help him understand what's happening?",
      evaluates: "Honest feedback delivery, tact, and constructive criticism"
    },
    %{
      id: :judgment_1,
      category: :style,
      scenario:
        "A man shares a photo of his dating profile and asks: \"I'm not getting any matches. Be honest — what's wrong with how I'm presenting myself?\"",
      prompt: "How would you approach giving him honest, actionable feedback?",
      evaluates: "Directness balanced with kindness, actionable advice"
    },
    %{
      id: :complexity_1,
      category: :dating_dynamics,
      scenario:
        "A man writes: \"My ex wants to get back together. Part of me wants to, but my friends all say it's a bad idea. She's changed, I think. How do I figure this out?\"",
      prompt: "What perspective would you offer?",
      evaluates: "Handling complexity, resisting oversimplification, respecting autonomy"
    }
  ]

  # Situational judgment — multiple choice to assess baseline values
  @judgment_questions [
    %{
      id: :sj_1,
      question: "A man asks you to validate a clearly manipulative dating tactic. How do you respond?",
      options: [
        %{key: "a", text: "Tell him what he wants to hear — he's paying for advice", score: 0},
        %{key: "b", text: "Ignore the question and move on", score: 1},
        %{key: "c", text: "Explain honestly why the approach is problematic and suggest a healthier alternative", score: 3},
        %{key: "d", text: "Lecture him about how wrong he is", score: 1}
      ]
    },
    %{
      id: :sj_2,
      question: "You receive a question that triggers a strong personal reaction based on your own experiences. What do you do?",
      options: [
        %{key: "a", text: "Respond with raw honesty — personal experience makes it more real", score: 1},
        %{key: "b", text: "Skip the question entirely", score: 1},
        %{key: "c", text: "Acknowledge the complexity internally, then respond with balanced perspective", score: 3},
        %{key: "d", text: "Tell him about your personal experience in detail", score: 0}
      ]
    },
    %{
      id: :sj_3,
      question: "A man's question reveals he may be in an emotionally abusive relationship. How do you handle it?",
      options: [
        %{key: "a", text: "Tell him to leave immediately", score: 1},
        %{key: "b", text: "Stay in your lane — you're not a therapist", score: 0},
        %{key: "c", text: "Validate his feelings, gently name what you're seeing, and suggest professional support", score: 3},
        %{key: "d", text: "Ask probing questions about the relationship details", score: 1}
      ]
    }
  ]

  @total_steps 4

  @impl true
  def mount(params, _session, socket) do
    token = params["token"]

    email =
      if token do
        case Phoenix.Token.verify(socket, "applicant_email", token, max_age: 3600) do
          {:ok, email} -> email
          _ -> nil
        end
      end

    unless email do
      {:ok,
       socket
       |> put_flash(:error, "Please enter your email to apply.")
       |> redirect(to: ~p"/contributors/join")}
    else
      # Check if this email already has a pending or approved application
      alias WorthAsking.Accounts
      existing_user = Accounts.get_user_by_email(email)

      existing_profile =
        if existing_user,
          do: Contributors.get_profile_by_user(existing_user.id),
          else: nil

      cond do
        existing_profile && existing_profile.application_status == :approved ->
          {:ok,
           socket
           |> assign(:page_title, "Already Approved")
           |> assign(:applicant_email, email)
           |> assign(:step, :already_approved)}

        existing_profile && existing_profile.application_status == :pending ->
          {:ok,
           socket
           |> assign(:page_title, "Application Submitted")
           |> assign(:applicant_email, email)
           |> assign(:step, :submitted)}

        true ->
          # Select 3 scenario questions for this applicant
          scenarios = @scenario_questions |> Enum.shuffle() |> Enum.take(3)

          {:ok,
           socket
           |> assign(:page_title, "Become a Contributor")
           |> assign(:applicant_email, email)
           |> assign(:total_steps, @total_steps)
           |> assign(:step, 1)
           |> assign(:display_name, "")
           |> assign(:bio, "")
           |> assign(:categories, [])
           |> assign(:scenario_questions, scenarios)
           |> assign(:scenario_responses, %{})
           |> assign(:judgment_answers, %{})
           |> assign(:motivation, "")
           |> assign(:agreement, false)
           |> assign(:error, nil)}
      end
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto px-6 py-12">
      <a href={~p"/"} class="text-sm text-[#6F8F9D] hover:underline mb-8 inline-block">
        &larr; Back
      </a>

      <%!-- Active application flow --%>
      <%= if is_integer(@step) and @step <= @total_steps do %>
        <%!-- Progress bar --%>
        <div class="mb-10">
          <div class="flex items-center justify-between mb-2">
            <span class="text-xs font-medium text-[#2F2F2F]/50">Step {@step} of {@total_steps}</span>
            <span class="text-xs text-[#2F2F2F]/40">{step_label(@step)}</span>
          </div>
          <div class="w-full h-1.5 bg-[#E4E6E3] rounded-full">
            <div
              class="h-1.5 bg-[#6F8F6B] rounded-full transition-all duration-300"
              style={"width: #{@step / @total_steps * 100}%"}
            >
            </div>
          </div>
        </div>

        <%= if @error do %>
          <div class="bg-red-50 border border-red-200 text-red-700 text-sm rounded-lg p-4 mb-6">
            {@error}
          </div>
        <% end %>
      <% end %>

      <%!-- Step 1: About you --%>
      <%= if @step == 1 do %>
        <h1 class="text-2xl font-semibold text-[#2F2F2F] mb-2" style="font-family: Georgia, serif;">
          About you
        </h1>
        <p class="text-sm text-[#2F2F2F]/60 mb-8">
          Tell us who you are. This helps us match you with the right questions.
        </p>

        <.form for={%{}} phx-submit="step_1_submit" class="space-y-6">
          <div>
            <label class="block text-sm font-medium text-[#2F2F2F] mb-2">Display name</label>
            <input
              type="text"
              name="display_name"
              value={@display_name}
              placeholder="A name or alias (shown to questioners)"
              required
              class="w-full border border-[#E4E6E3] rounded-lg p-3 text-sm focus:outline-none focus:border-[#6F8F9D] focus:ring-1 focus:ring-[#6F8F9D] bg-white"
            />
            <p class="text-xs text-[#2F2F2F]/40 mt-1">This can be a first name, nickname, or alias. You stay anonymous.</p>
          </div>

          <div>
            <label class="block text-sm font-medium text-[#2F2F2F] mb-2">Tell us about yourself</label>
            <textarea
              name="bio"
              rows="4"
              placeholder="What life experience, perspective, or expertise do you bring? Why are you a good person to give advice?"
              required
              class="w-full border border-[#E4E6E3] rounded-lg p-3 text-sm resize-none focus:outline-none focus:border-[#6F8F9D] focus:ring-1 focus:ring-[#6F8F9D] bg-white"
            >{@bio}</textarea>
          </div>

          <div>
            <label class="block text-sm font-medium text-[#2F2F2F] mb-2">Why do you want to be a contributor?</label>
            <textarea
              name="motivation"
              rows="3"
              placeholder="What draws you to this? What do you hope to help with?"
              required
              class="w-full border border-[#E4E6E3] rounded-lg p-3 text-sm resize-none focus:outline-none focus:border-[#6F8F9D] focus:ring-1 focus:ring-[#6F8F9D] bg-white"
            >{@motivation}</textarea>
          </div>

          <div>
            <label class="block text-sm font-medium text-[#2F2F2F] mb-3">
              Which topics do you feel confident advising on?
            </label>
            <div class="grid grid-cols-2 gap-3">
              <label
                :for={cat <- all_categories()}
                class={[
                  "flex items-center gap-3 border rounded-lg p-4 cursor-pointer transition-colors bg-white",
                  if(cat in @categories,
                    do: "border-[#6F8F6B] bg-[#A8BDA4]/5",
                    else: "border-[#E4E6E3] hover:border-[#A8BDA4]"
                  )
                ]}
              >
                <input
                  type="checkbox"
                  name="categories[]"
                  value={cat}
                  checked={cat in @categories}
                  class="rounded border-[#E4E6E3] text-[#6F8F6B] focus:ring-[#6F8F6B]"
                />
                <div>
                  <span class="text-sm font-medium text-[#2F2F2F]">
                    {format_category(cat)}
                  </span>
                  <p class="text-xs text-[#2F2F2F]/40">{category_description(cat)}</p>
                </div>
              </label>
            </div>
          </div>

          <button
            type="submit"
            class="w-full py-3 rounded-lg text-sm font-medium bg-[#6F8F6B] text-white hover:bg-[#5a7a57] transition-colors"
          >
            Continue
          </button>
        </.form>
      <% end %>

      <%!-- Step 2: Scenario responses --%>
      <%= if @step == 2 do %>
        <h1 class="text-2xl font-semibold text-[#2F2F2F] mb-2" style="font-family: Georgia, serif;">
          How would you respond?
        </h1>
        <p class="text-sm text-[#2F2F2F]/60 mb-2">
          These are real-world scenarios. Respond as you would to an actual user on the platform.
        </p>
        <p class="text-xs text-[#A8BDA4] mb-8">
          We're looking for empathy, honesty, nuance, and actionable perspective. There are no trick questions.
        </p>

        <.form for={%{}} phx-submit="step_2_submit" class="space-y-8">
          <div
            :for={{scenario, idx} <- Enum.with_index(@scenario_questions)}
            class="space-y-3"
          >
            <div class="bg-white border border-[#E4E6E3] rounded-lg p-5">
              <div class="flex items-center gap-2 mb-3">
                <span class="text-xs font-medium px-2 py-1 rounded-full bg-[#A8BDA4]/20 text-[#6F8F6B]">
                  Scenario {idx + 1}
                </span>
                <span class="text-xs text-[#2F2F2F]/30">
                  {format_category(scenario.category)}
                </span>
              </div>
              <p class="text-sm text-[#2F2F2F] leading-relaxed italic mb-3">{scenario.scenario}</p>
              <p class="text-sm font-medium text-[#2F2F2F]">{scenario.prompt}</p>
            </div>
            <div class="relative">
              <textarea
                name={"scenario_#{scenario.id}"}
                rows="6"
                placeholder="Write your response... Take your time, be thoughtful."
                required
                class="w-full border border-[#E4E6E3] rounded-lg p-3 text-sm resize-none focus:outline-none focus:border-[#6F8F9D] focus:ring-1 focus:ring-[#6F8F9D] bg-white"
              >{Map.get(@scenario_responses, scenario.id, "")}</textarea>
              <p class="text-xs text-[#2F2F2F]/30 mt-1">
                Aim for 3-5 sentences. Quality over length.
              </p>
            </div>
          </div>

          <div class="flex gap-3">
            <button
              type="button"
              phx-click="go_back"
              class="flex-1 py-3 rounded-lg text-sm font-medium border border-[#E4E6E3] text-[#2F2F2F] hover:bg-[#E4E6E3]/30 transition-colors"
            >
              Back
            </button>
            <button
              type="submit"
              class="flex-1 py-3 rounded-lg text-sm font-medium bg-[#6F8F6B] text-white hover:bg-[#5a7a57] transition-colors"
            >
              Continue
            </button>
          </div>
        </.form>
      <% end %>

      <%!-- Step 3: Situational judgment --%>
      <%= if @step == 3 do %>
        <h1 class="text-2xl font-semibold text-[#2F2F2F] mb-2" style="font-family: Georgia, serif;">
          Situational judgment
        </h1>
        <p class="text-sm text-[#2F2F2F]/60 mb-8">
          Choose the response that best reflects how you'd handle each situation.
        </p>

        <.form for={%{}} phx-submit="step_3_submit" class="space-y-8">
          <div
            :for={{jq, idx} <- Enum.with_index(judgment_questions())}
            class="bg-white border border-[#E4E6E3] rounded-lg p-6"
          >
            <p class="text-sm font-medium text-[#2F2F2F] mb-4">{idx + 1}. {jq.question}</p>
            <div class="space-y-2">
              <label
                :for={opt <- jq.options}
                class={[
                  "flex items-start gap-3 border rounded-lg p-3 cursor-pointer transition-colors",
                  if(Map.get(@judgment_answers, jq.id) == opt.key,
                    do: "border-[#6F8F6B] bg-[#A8BDA4]/5",
                    else: "border-[#E4E6E3] hover:border-[#A8BDA4]"
                  )
                ]}
              >
                <input
                  type="radio"
                  name={"judgment_#{jq.id}"}
                  value={opt.key}
                  checked={Map.get(@judgment_answers, jq.id) == opt.key}
                  class="mt-0.5 border-[#E4E6E3] text-[#6F8F6B] focus:ring-[#6F8F6B]"
                />
                <span class="text-sm text-[#2F2F2F]/80">{opt.text}</span>
              </label>
            </div>
          </div>

          <div class="flex gap-3">
            <button
              type="button"
              phx-click="go_back"
              class="flex-1 py-3 rounded-lg text-sm font-medium border border-[#E4E6E3] text-[#2F2F2F] hover:bg-[#E4E6E3]/30 transition-colors"
            >
              Back
            </button>
            <button
              type="submit"
              class="flex-1 py-3 rounded-lg text-sm font-medium bg-[#6F8F6B] text-white hover:bg-[#5a7a57] transition-colors"
            >
              Continue
            </button>
          </div>
        </.form>
      <% end %>

      <%!-- Step 4: Review & submit --%>
      <%= if @step == 4 do %>
        <h1 class="text-2xl font-semibold text-[#2F2F2F] mb-2" style="font-family: Georgia, serif;">
          Review your application
        </h1>
        <p class="text-sm text-[#2F2F2F]/60 mb-8">
          Make sure everything looks good before submitting.
        </p>

        <div class="space-y-6 mb-8">
          <%!-- Profile summary --%>
          <div class="bg-white border border-[#E4E6E3] rounded-lg p-6">
            <div class="flex items-center justify-between mb-4">
              <h3 class="text-sm font-medium text-[#2F2F2F]/50 uppercase tracking-wider">Your profile</h3>
              <button phx-click="edit_step" phx-value-step="1" class="text-xs text-[#6F8F9D] hover:underline">Edit</button>
            </div>
            <div class="space-y-3">
              <div>
                <p class="text-xs text-[#2F2F2F]/40">Display name</p>
                <p class="text-sm font-medium">{@display_name}</p>
              </div>
              <div>
                <p class="text-xs text-[#2F2F2F]/40">About</p>
                <p class="text-sm text-[#2F2F2F]/80">{@bio}</p>
              </div>
              <div>
                <p class="text-xs text-[#2F2F2F]/40">Motivation</p>
                <p class="text-sm text-[#2F2F2F]/80">{@motivation}</p>
              </div>
              <div>
                <p class="text-xs text-[#2F2F2F]/40">Categories</p>
                <div class="flex gap-2 mt-1">
                  <span
                    :for={cat <- @categories}
                    class="text-xs font-medium px-2 py-1 rounded-full bg-[#A8BDA4]/20 text-[#6F8F6B]"
                  >
                    {format_category(cat)}
                  </span>
                </div>
              </div>
            </div>
          </div>

          <%!-- Scenario responses summary --%>
          <div class="bg-white border border-[#E4E6E3] rounded-lg p-6">
            <div class="flex items-center justify-between mb-4">
              <h3 class="text-sm font-medium text-[#2F2F2F]/50 uppercase tracking-wider">Your responses</h3>
              <button phx-click="edit_step" phx-value-step="2" class="text-xs text-[#6F8F9D] hover:underline">Edit</button>
            </div>
            <div class="space-y-4">
              <div :for={{scenario, _idx} <- Enum.with_index(@scenario_questions)}>
                <p class="text-xs text-[#2F2F2F]/40 mb-1 italic">"{truncate(scenario.scenario, 80)}"</p>
                <p class="text-sm text-[#2F2F2F]/80">{Map.get(@scenario_responses, scenario.id, "")}</p>
              </div>
            </div>
          </div>
        </div>

        <%!-- Agreement --%>
        <div class="bg-[#F7F7F5] border border-[#E4E6E3] rounded-lg p-6 mb-8">
          <h3 class="text-sm font-medium text-[#2F2F2F] mb-3">Before you submit</h3>
          <ul class="space-y-2 text-sm text-[#2F2F2F]/70 mb-4">
            <li class="flex items-start gap-2">
              <span class="text-[#6F8F6B] mt-0.5">&#8226;</span>
              I'll respond with empathy, honesty, and respect
            </li>
            <li class="flex items-start gap-2">
              <span class="text-[#6F8F6B] mt-0.5">&#8226;</span>
              I understand my responses will be reviewed for quality
            </li>
            <li class="flex items-start gap-2">
              <span class="text-[#6F8F6B] mt-0.5">&#8226;</span>
              I'll maintain appropriate boundaries and suggest professional help when needed
            </li>
          </ul>
          <label class="flex items-center gap-3 cursor-pointer">
            <input
              type="checkbox"
              phx-click="toggle_agreement"
              checked={@agreement}
              class="rounded border-[#E4E6E3] text-[#6F8F6B] focus:ring-[#6F8F6B]"
            />
            <span class="text-sm font-medium text-[#2F2F2F]">I agree to these guidelines</span>
          </label>
        </div>

        <div class="flex gap-3">
          <button
            phx-click="go_back"
            class="flex-1 py-3 rounded-lg text-sm font-medium border border-[#E4E6E3] text-[#2F2F2F] hover:bg-[#E4E6E3]/30 transition-colors"
          >
            Back
          </button>
          <button
            phx-click="submit_application"
            disabled={not @agreement}
            class={[
              "flex-1 py-3 rounded-lg text-sm font-medium transition-colors",
              if(@agreement,
                do: "bg-[#6F8F6B] text-white hover:bg-[#5a7a57]",
                else: "bg-[#E4E6E3] text-[#2F2F2F]/40 cursor-not-allowed"
              )
            ]}
          >
            Submit application
          </button>
        </div>
      <% end %>

      <%!-- Confirmation / already submitted --%>
      <%= if @step == :submitted do %>
        <div class="text-center py-16">
          <div class="w-14 h-14 rounded-full bg-[#A8BDA4]/20 flex items-center justify-center mx-auto mb-5">
            <span class="text-[#6F8F6B] text-2xl">&#10003;</span>
          </div>
          <h1 class="text-2xl font-semibold text-[#2F2F2F] mb-3" style="font-family: Georgia, serif;">
            Application submitted
          </h1>
          <p class="text-sm text-[#2F2F2F]/60 mb-3 max-w-md mx-auto">
            Thank you for taking the time to apply. We review every application carefully to maintain the quality of our contributor community.
          </p>
          <p class="text-sm text-[#2F2F2F]/60 mb-8 max-w-md mx-auto">
            You'll receive an email within 48 hours with our decision.
          </p>
          <a
            href={~p"/"}
            class="bg-[#6F8F6B] text-white px-6 py-3 rounded-lg text-sm font-medium hover:bg-[#5a7a57] transition-colors inline-block"
          >
            Back to home
          </a>
        </div>
      <% end %>

      <%!-- Already approved --%>
      <%= if @step == :already_approved do %>
        <div class="text-center py-16">
          <div class="w-14 h-14 rounded-full bg-[#A8BDA4]/20 flex items-center justify-center mx-auto mb-5">
            <span class="text-[#6F8F6B] text-2xl">&#9734;</span>
          </div>
          <h1 class="text-2xl font-semibold text-[#2F2F2F] mb-3" style="font-family: Georgia, serif;">
            You're already approved!
          </h1>
          <p class="text-sm text-[#2F2F2F]/60 mb-8 max-w-md mx-auto">
            Check your email for the onboarding link to set up your profile and get started.
          </p>
          <a
            href={~p"/"}
            class="bg-[#6F8F6B] text-white px-6 py-3 rounded-lg text-sm font-medium hover:bg-[#5a7a57] transition-colors inline-block"
          >
            Back to home
          </a>
        </div>
      <% end %>
    </div>
    """
  end

  # --- Events ---

  @impl true
  def handle_event("step_1_submit", params, socket) do
    display_name = String.trim(params["display_name"] || "")
    bio = String.trim(params["bio"] || "")
    motivation = String.trim(params["motivation"] || "")
    categories = (params["categories"] || []) |> Enum.map(&String.to_existing_atom/1)

    cond do
      String.length(display_name) < 2 ->
        {:noreply, assign(socket, :error, "Display name must be at least 2 characters.")}

      String.length(bio) < 20 ->
        {:noreply, assign(socket, :error, "Please write a bit more about yourself (at least a couple sentences).")}

      String.length(motivation) < 20 ->
        {:noreply, assign(socket, :error, "Please share more about why you want to be a contributor.")}

      categories == [] ->
        {:noreply, assign(socket, :error, "Please select at least one category.")}

      true ->
        {:noreply,
         socket
         |> assign(:display_name, display_name)
         |> assign(:bio, bio)
         |> assign(:motivation, motivation)
         |> assign(:categories, categories)
         |> assign(:error, nil)
         |> assign(:step, 2)}
    end
  end

  @impl true
  def handle_event("step_2_submit", params, socket) do
    scenarios = socket.assigns.scenario_questions

    responses =
      Enum.reduce(scenarios, %{}, fn scenario, acc ->
        text = String.trim(params["scenario_#{scenario.id}"] || "")
        Map.put(acc, scenario.id, text)
      end)

    too_short =
      Enum.any?(responses, fn {_id, text} -> String.length(text) < 30 end)

    if too_short do
      {:noreply, assign(socket, :error, "Each response should be at least a few sentences. Take your time.")}
    else
      {:noreply,
       socket
       |> assign(:scenario_responses, responses)
       |> assign(:error, nil)
       |> assign(:step, 3)}
    end
  end

  @impl true
  def handle_event("step_3_submit", params, socket) do
    jqs = judgment_questions()

    answers =
      Enum.reduce(jqs, %{}, fn jq, acc ->
        key = params["judgment_#{jq.id}"]
        if key, do: Map.put(acc, jq.id, key), else: acc
      end)

    if map_size(answers) < length(jqs) do
      {:noreply, assign(socket, :error, "Please answer all questions.")}
    else
      {:noreply,
       socket
       |> assign(:judgment_answers, answers)
       |> assign(:error, nil)
       |> assign(:step, 4)}
    end
  end

  @impl true
  def handle_event("toggle_agreement", _params, socket) do
    {:noreply, assign(socket, :agreement, !socket.assigns.agreement)}
  end

  @impl true
  def handle_event("go_back", _params, socket) do
    prev = if is_integer(socket.assigns.step), do: max(socket.assigns.step - 1, 1), else: 1
    {:noreply, assign(socket, step: prev, error: nil)}
  end

  @impl true
  def handle_event("edit_step", %{"step" => step}, socket) do
    {:noreply, assign(socket, step: String.to_integer(step), error: nil)}
  end

  @impl true
  def handle_event("submit_application", _params, socket) do
    email = socket.assigns.applicant_email

    # Find or create the user
    alias WorthAsking.Accounts
    alias WorthAsking.Accounts.User

    user =
      case Accounts.get_user_by_email(email) do
        %User{} = existing -> {:ok, existing}
        nil -> Accounts.register_user(%{email: email})
      end

    case user do
      {:ok, user} ->
        # Confirm user if needed
        user =
          if user.confirmed_at do
            user
          else
            {:ok, confirmed} =
              user
              |> User.confirm_changeset()
              |> WorthAsking.Repo.update()
            confirmed
          end

        # Build sample_responses as a structured map for admin review
        scenario_data =
          socket.assigns.scenario_questions
          |> Enum.map(fn scenario ->
            %{
              "scenario" => scenario.scenario,
              "category" => to_string(scenario.category),
              "evaluates" => scenario.evaluates,
              "response" => Map.get(socket.assigns.scenario_responses, scenario.id, "")
            }
          end)

        # Score judgment answers
        judgment_score = calculate_judgment_score(socket.assigns.judgment_answers)

        judgment_data =
          judgment_questions()
          |> Enum.map(fn jq ->
            chosen = Map.get(socket.assigns.judgment_answers, jq.id)
            %{"question" => jq.question, "answer" => chosen}
          end)

        sample_responses = %{
          "scenarios" => scenario_data,
          "judgment" => judgment_data,
          "judgment_score" => judgment_score,
          "motivation" => socket.assigns.motivation
        }

        attrs = %{
          display_name: socket.assigns.display_name,
          bio: socket.assigns.bio,
          categories: socket.assigns.categories,
          sample_responses: sample_responses
        }

        case Contributors.apply_as_contributor(user, attrs) do
          {:ok, _profile} ->
            # Send "application under review" email
            UserNotifier.deliver_application_received(user)

            {:noreply,
             socket
             |> assign(:error, nil)
             |> assign(:step, :submitted)}

          {:error, _changeset} ->
            {:noreply, assign(socket, :error, "Something went wrong. Please try again.")}
        end

      {:error, _changeset} ->
        {:noreply, assign(socket, :error, "Something went wrong with your email. Please try again.")}
    end
  end

  # --- Helpers ---

  defp all_categories, do: @categories
  defp judgment_questions, do: @judgment_questions

  defp calculate_judgment_score(answers) do
    @judgment_questions
    |> Enum.reduce(0, fn jq, total ->
      chosen_key = Map.get(answers, jq.id)

      score =
        Enum.find_value(jq.options, 0, fn opt ->
          if opt.key == chosen_key, do: opt.score
        end)

      total + score
    end)
  end

  defp format_category(cat) do
    cat |> to_string() |> String.replace("_", " ") |> String.split(" ") |> Enum.map(&String.capitalize/1) |> Enum.join(" ")
  end

  defp category_description(:communication), do: "Texting, hard conversations, saying what you mean"
  defp category_description(:first_impressions), do: "Body language, approachability, social reads"
  defp category_description(:style), do: "Grooming, fashion, personal presentation"
  defp category_description(:dating_dynamics), do: "Signals, timing, relationship navigation"

  defp step_label(1), do: "About you"
  defp step_label(2), do: "Scenario responses"
  defp step_label(3), do: "Situational judgment"
  defp step_label(4), do: "Review & submit"

  defp truncate(text, max) do
    if String.length(text) > max, do: String.slice(text, 0, max) <> "...", else: text
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end
end
