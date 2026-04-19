defmodule WorthAskingWeb.ContributorResponseLive do
  use WorthAskingWeb, :live_view

  alias WorthAsking.Questions
  alias WorthAsking.Contributors
  alias WorthAsking.Notifications

  @impl true
  def mount(%{"question_id" => question_id}, _session, socket) do
    user = socket.assigns.current_scope.user
    question = Questions.get_question_with_responses!(question_id)
    profile = Contributors.get_profile_by_user(user.id)

    socket =
      socket
      |> assign(:page_title, "Respond to Question")
      |> assign(:question, question)
      |> assign(:profile, profile)
      |> assign(:response_text, "")
      |> assign(:error, nil)
      |> assign(:char_count, 0)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-xl mx-auto px-6 py-12" style="background-color: #F7F7F5; min-height: 100vh;">
      <a href={~p"/dashboard"} class="text-sm text-[#6F8F9D] hover:underline mb-8 inline-block">
        &larr; Back to dashboard
      </a>

      <%!-- Question card --%>
      <div class="bg-white border border-[#E4E6E3] rounded-lg p-6 mb-8">
        <div class="flex items-center gap-2 mb-3">
          <span class="text-xs font-medium px-2 py-1 rounded-full bg-[#A8BDA4]/20 text-[#6F8F6B]">
            {@question.category |> to_string() |> String.replace("_", " ") |> String.split(" ") |> Enum.map(&String.capitalize/1) |> Enum.join(" ")}
          </span>
        </div>
        <p class="text-base text-[#2F2F2F] leading-relaxed">{@question.text}</p>

        <%!-- Attached images --%>
        <%= if @question.image_paths != [] do %>
          <div class="mt-4 flex flex-wrap gap-3">
            <div :for={path <- @question.image_paths} class="w-24 h-24 rounded-lg overflow-hidden border border-[#E4E6E3]">
              <img src={path} alt="Attached image" class="w-full h-full object-cover" />
            </div>
          </div>
        <% end %>
      </div>

      <h2 class="text-lg font-semibold text-[#2F2F2F] mb-4" style="font-family: Georgia, serif;">
        Write your response
      </h2>

      <%= if @error do %>
        <div class="bg-red-50 border border-red-200 text-red-700 text-sm rounded-lg p-4 mb-4">
          {@error}
        </div>
      <% end %>

      <.form for={%{}} phx-submit="submit_response" phx-change="validate_response" class="space-y-4">
        <div>
          <textarea
            name="text"
            rows="8"
            placeholder="Share your thoughtful perspective..."
            class="w-full border border-[#E4E6E3] rounded-lg p-4 text-sm resize-none focus:outline-none focus:border-[#6F8F9D] focus:ring-1 focus:ring-[#6F8F9D] bg-white leading-relaxed"
          >{@response_text}</textarea>
          <div class="flex justify-between items-center mt-2">
            <p class={[
              "text-xs",
              if(@char_count < 20, do: "text-[#2F2F2F]/40", else: "text-[#6F8F6B]")
            ]}>
              {@char_count} characters
              <%= if @char_count < 20 do %>
                <span class="text-[#2F2F2F]/30">(minimum 20)</span>
              <% end %>
            </p>
          </div>
        </div>

        <button
          type="submit"
          disabled={@char_count < 20}
          class={[
            "w-full py-3 rounded-lg text-sm font-medium transition-colors",
            if(@char_count >= 20,
              do: "bg-[#6F8F9D] text-white hover:bg-[#5a7a87]",
              else: "bg-[#E4E6E3] text-[#2F2F2F]/40 cursor-not-allowed"
            )
          ]}
        >
          Submit response
        </button>
      </.form>
    </div>
    """
  end

  @impl true
  def handle_event("validate_response", %{"text" => text}, socket) do
    {:noreply,
     socket
     |> assign(:response_text, text)
     |> assign(:char_count, String.length(String.trim(text)))}
  end

  @impl true
  def handle_event("submit_response", %{"text" => text}, socket) do
    trimmed = String.trim(text)

    if String.length(trimmed) < 20 do
      {:noreply, assign(socket, :error, "Response must be at least 20 characters.")}
    else
      user = socket.assigns.current_scope.user
      question = socket.assigns.question

      case Questions.create_response(question, user, %{"text" => trimmed}) do
        {:ok, _response} ->
          # Release session lock if assigned
          if profile = socket.assigns.profile do
            Notifications.release_session(profile)
          end

          {:noreply,
           socket
           |> put_flash(:info, "Response submitted successfully!")
           |> redirect(to: ~p"/dashboard")}

        {:error, _changeset} ->
          {:noreply, assign(socket, :error, "Something went wrong. Please try again.")}
      end
    end
  end
end
