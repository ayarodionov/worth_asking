defmodule WorthAskingWeb.QuestionLive do
  use WorthAskingWeb, :live_view

  alias WorthAsking.Questions
  alias WorthAsking.Questions.Question

  @impl true
  def mount(params, _session, socket) do
    initial_text = params["q"] || ""

    socket =
      socket
      |> assign(:page_title, "Ask a Question")
      |> assign(:step, :compose)
      |> assign(:question_text, initial_text)
      |> assign(:category, nil)
      |> assign(:changeset, Question.changeset(%Question{}, %{}))
      |> allow_upload(:images,
        accept: ~w(.jpg .jpeg .png .gif .webp),
        max_entries: 3,
        max_file_size: 5_000_000
      )

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-xl mx-auto px-6 py-12">
      <a href={~p"/"} class="text-sm text-[#6F8F9D] hover:underline mb-8 inline-block">
        &larr; Back
      </a>

      <%= if @step == :compose do %>
        <h1 class="text-2xl font-semibold mb-6" style="font-family: Georgia, serif;">
          What's on your mind?
        </h1>

        <.form for={@changeset} phx-submit="submit_question" phx-change="validate" class="space-y-6">
          <div>
            <textarea
              name="question[text]"
              rows="5"
              placeholder="Type your question..."
              class="w-full border border-[#E4E6E3] rounded-lg p-4 text-base resize-none focus:outline-none focus:border-[#6F8F9D] focus:ring-1 focus:ring-[#6F8F9D] bg-white"
            >{@question_text}</textarea>
          </div>

          <%!-- Photo upload --%>
          <div>
            <p class="text-sm font-medium text-[#2F2F2F]/70 mb-3">Attach images (optional, up to 3)</p>
            <div class="border-2 border-dashed border-[#E4E6E3] rounded-lg p-6 text-center" phx-drop-target={@uploads.images.ref}>
              <.live_file_input upload={@uploads.images} class="hidden" />
              <label for={@uploads.images.ref} class="cursor-pointer text-sm text-[#6F8F9D] hover:underline">
                Choose files or drag and drop
              </label>
            </div>

            <%!-- Preview thumbnails --%>
            <div :if={@uploads.images.entries != []} class="flex gap-3 mt-3">
              <div :for={entry <- @uploads.images.entries} class="relative">
                <.live_img_preview entry={entry} class="w-20 h-20 object-cover rounded-lg border border-[#E4E6E3]" />
                <button
                  type="button"
                  phx-click="cancel_upload"
                  phx-value-ref={entry.ref}
                  class="absolute -top-2 -right-2 w-5 h-5 bg-red-500 text-white rounded-full text-xs flex items-center justify-center"
                >
                  &times;
                </button>
                <p :for={err <- upload_errors(@uploads.images, entry)} class="text-red-500 text-xs mt-1">
                  {error_to_string(err)}
                </p>
              </div>
            </div>
          </div>

          <div>
            <p class="text-sm font-medium text-[#2F2F2F]/70 mb-3">Select a category</p>
            <div class="grid grid-cols-2 gap-3">
              <label
                :for={cat <- [:communication, :first_impressions, :style, :dating_dynamics]}
                class={[
                  "border rounded-lg p-4 cursor-pointer transition-colors text-center",
                  if(@category == cat,
                    do: "border-[#6F8F9D] bg-[#6F8F9D]/5",
                    else: "border-[#E4E6E3] hover:border-[#A8BDA4]"
                  )
                ]}
              >
                <input
                  type="radio"
                  name="question[category]"
                  value={cat}
                  checked={@category == cat}
                  phx-click="select_category"
                  phx-value-category={cat}
                  class="sr-only"
                />
                <span class="text-sm font-medium">
                  {format_category(cat)}
                </span>
              </label>
            </div>
          </div>

          <button
            type="submit"
            disabled={@category == nil}
            class={[
              "w-full py-3 rounded-lg text-sm font-medium transition-colors",
              if(@category,
                do: "bg-[#6F8F9D] text-white hover:bg-[#5a7a87]",
                else: "bg-[#E4E6E3] text-[#2F2F2F]/40 cursor-not-allowed"
              )
            ]}
          >
            Get a second perspective
          </button>
        </.form>

      <% else %>
        <div class="text-center py-12">
          <div class="w-12 h-12 rounded-full bg-[#A8BDA4]/20 flex items-center justify-center mx-auto mb-4">
            <span class="text-[#6F8F6B] text-xl">&#10003;</span>
          </div>
          <h1 class="text-2xl font-semibold mb-2" style="font-family: Georgia, serif;">
            Question submitted
          </h1>
          <p class="text-[#2F2F2F]/60 mb-8">
            You'll receive 3-5 thoughtful responses. We'll notify you when they're ready.
          </p>
          <a
            href={~p"/my-questions"}
            class="bg-[#6F8F9D] text-white px-6 py-3 rounded-lg text-sm font-medium hover:bg-[#5a7a87] transition-colors inline-block"
          >
            View my questions
          </a>
        </div>
      <% end %>
    </div>
    """
  end

  @impl true
  def handle_event("select_category", %{"category" => category}, socket) do
    {:noreply, assign(socket, :category, String.to_existing_atom(category))}
  end

  @impl true
  def handle_event("validate", %{"question" => params}, socket) do
    {:noreply, assign(socket, :question_text, params["text"] || "")}
  end

  @impl true
  def handle_event("cancel_upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :images, ref)}
  end

  @impl true
  def handle_event("submit_question", %{"question" => params}, socket) do
    user = socket.assigns.current_scope.user

    # Save uploaded images
    image_paths =
      consume_uploaded_entries(socket, :images, fn %{path: path}, entry ->
        uploads_dir = Path.join(["priv", "static", "uploads", "questions"])
        File.mkdir_p!(uploads_dir)
        filename = "#{Ecto.UUID.generate()}-#{entry.client_name}"
        dest = Path.join(uploads_dir, filename)
        File.cp!(path, dest)
        {:ok, "/uploads/questions/#{filename}"}
      end)

    attrs = %{
      "text" => params["text"],
      "category" => to_string(socket.assigns.category),
      "image_paths" => image_paths
    }

    case Questions.create_question(user, attrs) do
      {:ok, _question} ->
        {:noreply, assign(socket, :step, :submitted)}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  defp format_category(cat) do
    cat |> to_string() |> String.replace("_", " ") |> String.split(" ") |> Enum.map(&String.capitalize/1) |> Enum.join(" ")
  end

  defp error_to_string(:too_large), do: "Too large (max 5MB)"
  defp error_to_string(:not_accepted), do: "Invalid file type"
  defp error_to_string(:too_many_files), do: "Too many files"
  defp error_to_string(err), do: to_string(err)
end
