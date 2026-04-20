defmodule WorthAskingWeb.ContributorResponseLive do
  use WorthAskingWeb, :live_view

  alias WorthAsking.Questions
  alias WorthAsking.Questions.Response
  alias WorthAsking.Contributors
  alias WorthAsking.Notifications

  @min_chars 150

  @impl true
  def mount(%{"question_id" => question_id}, _session, socket) do
    user = socket.assigns.current_scope.user
    profile = Contributors.get_profile_by_user(user.id)

    # Check if question is full
    if Questions.question_full?(question_id) do
      {:ok,
       socket
       |> put_flash(:error, "This question has already received enough responses.")
       |> redirect(to: ~p"/dashboard")}
    else
      question = Questions.get_question_with_responses!(question_id)

      # Pre-fill alias from profile display_name, age_range from profile
      default_alias = profile && profile.display_name
      default_age = profile && profile.age_range

      {:ok,
       socket
       |> assign(:page_title, "Respond to Question")
       |> assign(:question, question)
       |> assign(:profile, profile)
       |> assign(:step, :compose)
       |> assign(:response_text, "")
       |> assign(:alias_name, default_alias || "")
       |> assign(:age_range, default_age || "")
       |> assign(:char_count, 0)
       |> assign(:min_chars, @min_chars)
       |> assign(:error, nil)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-xl mx-auto px-4 sm:px-6 py-8 sm:py-12">
      <a href={~p"/dashboard"} class="text-sm text-[#6F8F9D] hover:underline mb-8 inline-block">
        &larr; Back to dashboard
      </a>

      <%= if @step == :compose do %>
        <%!-- Question card --%>
        <div class="bg-white border border-[#E4E6E3] rounded-lg p-5 sm:p-6 mb-6">
          <div class="flex items-center gap-2 mb-3">
            <span class="text-xs font-medium px-2 py-1 rounded-full bg-[#A8BDA4]/20 text-[#6F8F6B]">
              {WorthAsking.Categories.label(@question.category)}
            </span>
          </div>
          <p class="text-base text-[#2F2F2F] leading-relaxed" style="font-family: Georgia, serif;">
            {@question.text}
          </p>
          <div :if={@question.image_paths != []} class="mt-4 flex flex-wrap gap-3">
            <div :for={path <- @question.image_paths} class="w-20 h-20 rounded-lg overflow-hidden border border-[#E4E6E3]">
              <img src={path} alt="Attached image" class="w-full h-full object-cover" />
            </div>
          </div>
        </div>

        <%!-- Response guidelines --%>
        <div class="mb-6">
          <p class="text-xs text-[#2F2F2F]/40 uppercase tracking-wider mb-3">Guidelines</p>
          <div class="space-y-1.5 text-xs text-[#2F2F2F]/50">
            <p>Be honest, not performative</p>
            <p>Speak from your own experience</p>
            <p>No need to be perfect — clarity over polish</p>
          </div>
        </div>

        <%!-- Urgency hint --%>
        <p class="text-xs text-[#2F2F2F]/30 mb-6">
          Responses typically close within ~30 minutes
        </p>

        <%= if @error do %>
          <div class="bg-red-50 border border-red-200 text-red-700 text-sm rounded-lg p-4 mb-4">
            {@error}
          </div>
        <% end %>

        <.form for={%{}} phx-submit="submit_response" phx-change="validate" class="space-y-5">
          <%!-- Main response input --%>
          <div>
            <label class="text-sm font-medium text-[#2F2F2F] mb-2 block">Your response</label>
            <textarea
              name="text"
              rows="8"
              placeholder="What would you honestly tell him if there were no social consequences?"
              class="w-full border border-[#E4E6E3] rounded-lg p-4 text-sm resize-none focus:outline-none focus:border-[#6F8F9D] focus:ring-1 focus:ring-[#6F8F9D] bg-white leading-relaxed"
            >{@response_text}</textarea>

            <%!-- Character count --%>
            <div class="flex justify-between items-center mt-2">
              <p class={[
                "text-xs",
                if(@char_count < @min_chars, do: "text-[#2F2F2F]/40", else: "text-[#6F8F6B]")
              ]}>
                {@char_count} characters
                <%= if @char_count < @min_chars do %>
                  <span class="text-[#2F2F2F]/30">(minimum {@min_chars})</span>
                <% end %>
              </p>
              <%= if @char_count > 800 do %>
                <p class="text-xs text-[#2F2F2F]/30">Getting long — keep it focused</p>
              <% end %>
            </div>
          </div>

          <%!-- Guiding prompts (not separate fields) --%>
          <div class="bg-[#F7F7F5] border border-[#E4E6E3] rounded-lg p-4">
            <p class="text-xs text-[#2F2F2F]/40 uppercase tracking-wider mb-2">Consider</p>
            <ul class="space-y-1.5 text-xs text-[#2F2F2F]/50">
              <li>What is he misunderstanding?</li>
              <li>What would you actually do in this situation?</li>
              <li>What matters most here?</li>
            </ul>
          </div>

          <%!-- Alias & age range --%>
          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="text-sm font-medium text-[#2F2F2F] mb-1.5 block">Your alias</label>
              <input
                type="text"
                name="alias_name"
                value={@alias_name}
                placeholder="e.g. Maya, Sage, Ren"
                maxlength="30"
                class="w-full border border-[#E4E6E3] rounded-lg px-3 py-2.5 text-sm focus:outline-none focus:border-[#6F8F9D] focus:ring-1 focus:ring-[#6F8F9D] bg-white"
              />
              <p class="text-xs text-[#2F2F2F]/30 mt-1">Not your real name</p>
            </div>
            <div>
              <label class="text-sm font-medium text-[#2F2F2F] mb-1.5 block">Age range</label>
              <select
                name="age_range"
                class="w-full border border-[#E4E6E3] rounded-lg px-3 py-2.5 text-sm focus:outline-none focus:border-[#6F8F9D] focus:ring-1 focus:ring-[#6F8F9D] bg-white"
              >
                <option value="" disabled selected={@age_range == ""}>Select</option>
                <option :for={range <- Response.age_ranges()} value={range} selected={@age_range == range}>
                  {range}
                </option>
              </select>
            </div>
          </div>

          <%!-- Submit --%>
          <button
            type="submit"
            disabled={@char_count < @min_chars}
            class={[
              "w-full py-3 rounded-lg text-sm font-medium transition-colors",
              if(@char_count >= @min_chars,
                do: "bg-[#6F8F9D] text-white hover:bg-[#5a7a87]",
                else: "bg-[#E4E6E3] text-[#2F2F2F]/40 cursor-not-allowed"
              )
            ]}
          >
            Submit Response
          </button>
        </.form>
      <% end %>

      <%!-- Submission confirmation --%>
      <%= if @step == :submitted do %>
        <div class="text-center py-16">
          <div class="w-14 h-14 rounded-full bg-[#A8BDA4]/20 flex items-center justify-center mx-auto mb-6">
            <span class="text-[#6F8F6B] text-2xl">&#10003;</span>
          </div>
          <h2 class="text-xl font-semibold text-[#2F2F2F] mb-3" style="font-family: Georgia, serif;">
            Your response has been sent
          </h2>
          <p class="text-sm text-[#2F2F2F]/50 mb-8 max-w-xs mx-auto">
            Thank you for sharing your perspective. It will be delivered to the person who asked.
          </p>
          <a
            href={~p"/dashboard"}
            class="inline-block bg-[#6F8F9D] text-white px-6 py-2.5 rounded-lg text-sm font-medium hover:bg-[#5a7a87] transition-colors"
          >
            Back to dashboard
          </a>
        </div>
      <% end %>
    </div>
    """
  end

  @impl true
  def handle_event("validate", params, socket) do
    text = Map.get(params, "text", "")
    alias_name = Map.get(params, "alias_name", socket.assigns.alias_name)
    age_range = Map.get(params, "age_range", socket.assigns.age_range)

    {:noreply,
     socket
     |> assign(:response_text, text)
     |> assign(:alias_name, alias_name)
     |> assign(:age_range, age_range)
     |> assign(:char_count, String.length(String.trim(text)))
     |> assign(:error, nil)}
  end

  @impl true
  def handle_event("submit_response", params, socket) do
    text = String.trim(Map.get(params, "text", ""))
    alias_name = String.trim(Map.get(params, "alias_name", ""))
    age_range = Map.get(params, "age_range", "")

    cond do
      String.length(text) < @min_chars ->
        {:noreply, assign(socket, :error, "Response must be at least #{@min_chars} characters.")}

      alias_name == "" ->
        {:noreply, assign(socket, :error, "Please provide an alias.")}

      age_range == "" ->
        {:noreply, assign(socket, :error, "Please select your age range.")}

      true ->
        user = socket.assigns.current_scope.user
        question = socket.assigns.question

        attrs = %{
          "text" => text,
          "alias_name" => alias_name,
          "age_range" => age_range
        }

        case Questions.create_response(question, user, attrs) do
          {:ok, _response} ->
            if profile = socket.assigns.profile do
              Notifications.release_session(profile)
            end

            {:noreply, assign(socket, :step, :submitted)}

          {:error, :question_full} ->
            {:noreply,
             socket
             |> put_flash(:error, "This question has already received enough responses.")
             |> redirect(to: ~p"/dashboard")}

          {:error, _changeset} ->
            {:noreply, assign(socket, :error, "Something went wrong. Please try again.")}
        end
    end
  end
end
