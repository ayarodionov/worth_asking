defmodule WorthAskingWeb.ContributorOnboardingLive do
  use WorthAskingWeb, :live_view

  alias WorthAsking.Contributors
  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    profile = Contributors.get_profile_by_user(user.id)

    if is_nil(profile) || profile.application_status != :approved do
      {:ok, push_navigate(socket, to: ~p"/")}
    else
      if profile.onboarding_completed do
        {:ok, push_navigate(socket, to: ~p"/dashboard")}
      else
        form = build_form(profile, user)

        socket =
          socket
          |> assign(:page_title, "Complete Your Contributor Profile")
          |> assign(:profile, profile)
          |> assign(:user, user)
          |> assign(:form, form)
          |> assign(:stripe_status, stripe_status(profile))

        {:ok, socket}
      end
    end
  end

  defp build_form(profile, user) do
    data = %{
      "first_name" => user.first_name || "",
      "last_name" => user.last_name || "",
      "display_name" => profile.display_name || "",
      "bio" => profile.bio || "",
      "age_range" => profile.age_range || "",
      "location" => profile.location || "",
      "phone" => user.phone || "",
      "sms_opt_in" => profile.sms_opt_in || false,
      "availability_preference" => profile.availability_preference || "anytime",
      "agreed_to_terms" => false,
      "agreed_to_sms" => false,
      "agreed_to_payout_terms" => false
    }

    Phoenix.Component.to_form(data, as: "onboarding")
  end

  defp stripe_status(profile) do
    cond do
      profile.stripe_connect_id && profile.stripe_connect_id != "" -> :connected
      true -> :not_connected
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto px-6 py-12 lg:py-16">
      <%!-- Progress indicator --%>
      <div class="flex items-center gap-3 mb-10">
        <div class="flex items-center gap-2">
          <div class="w-7 h-7 rounded-full bg-[#6F8F6B] flex items-center justify-center">
            <span class="text-xs font-semibold text-white">1</span>
          </div>
          <span class="text-sm font-medium text-[#2F2F2F]">Profile Setup</span>
        </div>
        <div class="flex-1 h-px bg-[#E4E6E3]"></div>
        <div class="flex items-center gap-2">
          <div class="w-7 h-7 rounded-full bg-[#E4E6E3] flex items-center justify-center">
            <span class="text-xs font-semibold text-[#2F2F2F]/40">2</span>
          </div>
          <span class="text-sm text-[#2F2F2F]/40">Guidelines</span>
        </div>
      </div>

      <%!-- Header --%>
      <header class="mb-10">
        <h1 class="text-2xl lg:text-3xl font-semibold tracking-tight text-[#2F2F2F] mb-3" style="font-family: Georgia, serif;">
          Complete Your Contributor Profile
        </h1>
        <p class="text-[#2F2F2F]/60 leading-relaxed">
          Welcome to Worth Asking.
          Complete your setup below so you can receive question alerts, get paid weekly, and start contributing.
        </p>
      </header>

      <.form for={@form} phx-submit="save_onboarding" class="space-y-10">
        <%!-- Section 1: Account Setup --%>
        <section class="bg-white border border-[#E4E6E3] rounded-lg p-6 lg:p-8">
          <h2 class="text-xs tracking-[0.2em] uppercase text-[#2F2F2F]/30 mb-6">Account Setup</h2>

          <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 mb-4">
            <div>
              <label class="block text-sm font-medium text-[#2F2F2F] mb-1">First Name</label>
              <input
                type="text"
                name="onboarding[first_name]"
                value={@form[:first_name].value}
                required
                class="w-full px-3 py-2 border border-[#E4E6E3] rounded-md text-sm focus:outline-none focus:ring-1 focus:ring-[#6F8F9D] focus:border-[#6F8F9D]"
              />
            </div>
            <div>
              <label class="block text-sm font-medium text-[#2F2F2F] mb-1">Last Name</label>
              <input
                type="text"
                name="onboarding[last_name]"
                value={@form[:last_name].value}
                required
                class="w-full px-3 py-2 border border-[#E4E6E3] rounded-md text-sm focus:outline-none focus:ring-1 focus:ring-[#6F8F9D] focus:border-[#6F8F9D]"
              />
            </div>
          </div>

          <div>
            <label class="block text-sm font-medium text-[#2F2F2F] mb-1">Email</label>
            <input
              type="email"
              value={@user.email}
              disabled
              class="w-full px-3 py-2 border border-[#E4E6E3] rounded-md text-sm bg-[#F7F7F5] text-[#2F2F2F]/50"
            />
          </div>

          <%= if !@user.hashed_password do %>
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 mt-4">
              <div>
                <label class="block text-sm font-medium text-[#2F2F2F] mb-1">Create Password</label>
                <input
                  type="password"
                  name="onboarding[password]"
                  autocomplete="new-password"
                  required
                  minlength="12"
                  class="w-full px-3 py-2 border border-[#E4E6E3] rounded-md text-sm focus:outline-none focus:ring-1 focus:ring-[#6F8F9D] focus:border-[#6F8F9D]"
                />
                <p class="text-xs text-[#2F2F2F]/40 mt-1">Minimum 12 characters</p>
              </div>
              <div>
                <label class="block text-sm font-medium text-[#2F2F2F] mb-1">Confirm Password</label>
                <input
                  type="password"
                  name="onboarding[password_confirmation]"
                  autocomplete="new-password"
                  required
                  minlength="12"
                  class="w-full px-3 py-2 border border-[#E4E6E3] rounded-md text-sm focus:outline-none focus:ring-1 focus:ring-[#6F8F9D] focus:border-[#6F8F9D]"
                />
              </div>
            </div>
          <% end %>
        </section>

        <%!-- Section 2: Public Profile --%>
        <section class="bg-white border border-[#E4E6E3] rounded-lg p-6 lg:p-8">
          <h2 class="text-xs tracking-[0.2em] uppercase text-[#2F2F2F]/30 mb-6">Public Contributor Profile</h2>

          <div class="space-y-4">
            <div>
              <label class="block text-sm font-medium text-[#2F2F2F] mb-1">Display Name / Alias</label>
              <input
                type="text"
                name="onboarding[display_name]"
                value={@form[:display_name].value}
                required
                class="w-full px-3 py-2 border border-[#E4E6E3] rounded-md text-sm focus:outline-none focus:ring-1 focus:ring-[#6F8F9D] focus:border-[#6F8F9D]"
              />
              <p class="text-xs text-[#2F2F2F]/40 mt-1">
                This is the name used on your contributor profile. It does not need to be your real full name.
              </p>
            </div>

            <div>
              <label class="block text-sm font-medium text-[#2F2F2F] mb-1">Age Range</label>
              <select
                name="onboarding[age_range]"
                class="w-full px-3 py-2 border border-[#E4E6E3] rounded-md text-sm focus:outline-none focus:ring-1 focus:ring-[#6F8F9D] focus:border-[#6F8F9D]"
              >
                <option value="">Select</option>
                <option value="18-24" selected={@form[:age_range].value == "18-24"}>18 &ndash; 24</option>
                <option value="25-34" selected={@form[:age_range].value == "25-34"}>25 &ndash; 34</option>
                <option value="35-44" selected={@form[:age_range].value == "35-44"}>35 &ndash; 44</option>
                <option value="45-54" selected={@form[:age_range].value == "45-54"}>45 &ndash; 54</option>
                <option value="55+" selected={@form[:age_range].value == "55+"}>55+</option>
              </select>
            </div>

            <div>
              <label class="block text-sm font-medium text-[#2F2F2F] mb-1">
                Location
                <span class="text-[#2F2F2F]/30 font-normal">(optional)</span>
              </label>
              <input
                type="text"
                name="onboarding[location]"
                value={@form[:location].value}
                placeholder="City, State or State"
                class="w-full px-3 py-2 border border-[#E4E6E3] rounded-md text-sm focus:outline-none focus:ring-1 focus:ring-[#6F8F9D] focus:border-[#6F8F9D]"
              />
            </div>

            <div>
              <label class="block text-sm font-medium text-[#2F2F2F] mb-1">Short Bio</label>
              <textarea
                name="onboarding[bio]"
                rows="3"
                maxlength="500"
                class="w-full px-3 py-2 border border-[#E4E6E3] rounded-md text-sm focus:outline-none focus:ring-1 focus:ring-[#6F8F9D] focus:border-[#6F8F9D] resize-none"
                placeholder="Share a little about your perspective, personality, or life experience."
              ><%= @form[:bio].value %></textarea>
              <p class="text-xs text-[#2F2F2F]/40 mt-1">2&ndash;4 sentences. This helps users understand your background.</p>
            </div>
          </div>
        </section>

        <%!-- Section 3: Question Alerts --%>
        <section class="bg-white border border-[#E4E6E3] rounded-lg p-6 lg:p-8">
          <h2 class="text-xs tracking-[0.2em] uppercase text-[#2F2F2F]/30 mb-6">Question Alert Setup</h2>

          <div class="space-y-4">
            <div>
              <label class="block text-sm font-medium text-[#2F2F2F] mb-1">Mobile Phone Number</label>
              <input
                type="tel"
                name="onboarding[phone]"
                value={@form[:phone].value}
                placeholder="+1 (555) 123-4567"
                autocomplete="tel"
                class="w-full px-3 py-2 border border-[#E4E6E3] rounded-md text-sm focus:outline-none focus:ring-1 focus:ring-[#6F8F9D] focus:border-[#6F8F9D]"
              />
              <p class="text-xs text-[#2F2F2F]/40 mt-1">
                We'll send you a text when a new question is routed to you. Your number is never shared.
              </p>
            </div>

            <div class="flex items-start gap-3">
              <input
                type="checkbox"
                name="onboarding[sms_opt_in]"
                value="true"
                checked={@form[:sms_opt_in].value == true || @form[:sms_opt_in].value == "true"}
                class="mt-1 rounded border-[#E4E6E3] text-[#6F8F6B] focus:ring-[#6F8F6B]"
              />
              <label class="text-sm text-[#2F2F2F]/70">
                I agree to receive SMS alerts when question opportunities are available.
              </label>
            </div>

            <div>
              <label class="block text-sm font-medium text-[#2F2F2F] mb-2">Availability Preference</label>
              <div class="grid grid-cols-2 sm:grid-cols-4 gap-2">
                <label
                  :for={opt <- [{"anytime", "Anytime"}, {"daytime", "Daytime"}, {"evenings", "Evenings"}, {"limited", "Limited"}]}
                  class={"flex items-center justify-center px-3 py-2 border rounded-md text-sm cursor-pointer transition-colors " <>
                    if(@form[:availability_preference].value == elem(opt, 0),
                      do: "border-[#6F8F6B] bg-[#6F8F6B]/5 text-[#6F8F6B]",
                      else: "border-[#E4E6E3] text-[#2F2F2F]/60 hover:border-[#6F8F9D]")}
                >
                  <input
                    type="radio"
                    name="onboarding[availability_preference]"
                    value={elem(opt, 0)}
                    checked={@form[:availability_preference].value == elem(opt, 0)}
                    class="sr-only"
                  />
                  {elem(opt, 1)}
                </label>
              </div>
            </div>
          </div>
        </section>

        <%!-- Section 4: Payout Setup --%>
        <section class="bg-white border border-[#E4E6E3] rounded-lg p-6 lg:p-8">
          <h2 class="text-xs tracking-[0.2em] uppercase text-[#2F2F2F]/30 mb-6">Set Up Weekly Payouts</h2>

          <p class="text-sm text-[#2F2F2F]/70 mb-4 leading-relaxed">
            Worth Asking uses Stripe to securely send weekly payouts.
            Your banking details are entered through Stripe's encrypted setup flow, not stored directly by us.
          </p>

          <div class="flex items-center gap-4 mb-4">
            <%= if @stripe_status == :connected do %>
              <div class="flex items-center gap-2 px-4 py-2 bg-[#6F8F6B]/10 border border-[#6F8F6B]/30 rounded-md">
                <svg class="w-4 h-4 text-[#6F8F6B]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/>
                </svg>
                <span class="text-sm font-medium text-[#6F8F6B]">Stripe Connected</span>
              </div>
            <% else %>
              <a
                href={~p"/stripe/connect/onboarding"}
                class="inline-flex items-center gap-2 px-5 py-2.5 bg-[#635BFF] text-white text-sm font-medium rounded-md hover:bg-[#534AE8] transition-colors"
              >
                <svg class="w-4 h-4" viewBox="0 0 24 24" fill="currentColor">
                  <path d="M13.976 9.15c-2.172-.806-3.356-1.426-3.356-2.409 0-.831.683-1.305 1.901-1.305 2.227 0 4.515.858 6.09 1.631l.89-5.494C18.252.975 15.697 0 12.165 0 9.667 0 7.589.654 6.104 1.872 4.56 3.147 3.757 4.992 3.757 7.218c0 4.039 2.467 5.76 6.476 7.219 2.585.92 3.445 1.574 3.445 2.583 0 .98-.84 1.545-2.354 1.545-1.875 0-4.965-.921-7.076-2.19l-.893 5.575C4.746 22.758 7.67 24 11.5 24c2.594 0 4.715-.64 6.227-1.834 1.634-1.28 2.477-3.178 2.477-5.603 0-4.108-2.577-5.798-6.228-7.413z"/>
                </svg>
                Connect with Stripe
              </a>
              <span class="text-xs text-[#2F2F2F]/40">Not yet connected</span>
            <% end %>
          </div>

          <p class="text-xs text-[#2F2F2F]/40 leading-relaxed">
            Contributors are paid weekly for accepted responses. Worth Asking does not store your banking details directly.
          </p>
        </section>

        <%!-- Section 5: Agreements --%>
        <section class="bg-white border border-[#E4E6E3] rounded-lg p-6 lg:p-8">
          <h2 class="text-xs tracking-[0.2em] uppercase text-[#2F2F2F]/30 mb-6">Confirmation</h2>

          <div class="space-y-3">
            <div class="flex items-start gap-3">
              <input
                type="checkbox"
                name="onboarding[agreed_to_terms]"
                value="true"
                required
                class="mt-1 rounded border-[#E4E6E3] text-[#6F8F6B] focus:ring-[#6F8F6B]"
              />
              <label class="text-sm text-[#2F2F2F]/70">
                I agree to the Contributor Terms.
              </label>
            </div>

            <div class="flex items-start gap-3">
              <input
                type="checkbox"
                name="onboarding[agreed_to_sms]"
                value="true"
                class="mt-1 rounded border-[#E4E6E3] text-[#6F8F6B] focus:ring-[#6F8F6B]"
              />
              <label class="text-sm text-[#2F2F2F]/70">
                I agree to receive text alerts related to Worth Asking opportunities.
              </label>
            </div>

            <div class="flex items-start gap-3">
              <input
                type="checkbox"
                name="onboarding[agreed_to_payout_terms]"
                value="true"
                class="mt-1 rounded border-[#E4E6E3] text-[#6F8F6B] focus:ring-[#6F8F6B]"
              />
              <label class="text-sm text-[#2F2F2F]/70">
                I understand payouts are issued weekly according to platform terms.
              </label>
            </div>
          </div>
        </section>

        <%!-- Submit --%>
        <div class="pt-2">
          <button
            type="submit"
            class="w-full py-3 bg-[#6F8F6B] text-white text-sm font-medium rounded-lg hover:bg-[#5a7a57] transition-colors"
          >
            Continue to Contributor Guidelines
          </button>
          <p class="text-xs text-center text-[#2F2F2F]/30 mt-3">
            You can update your profile at any time from your dashboard.
          </p>
        </div>
      </.form>
    </div>
    """
  end

  @impl true
  def handle_event("save_onboarding", %{"onboarding" => params}, socket) do
    profile = socket.assigns.profile
    user = socket.assigns.user

    # Validate password if user doesn't have one yet
    password = params["password"]
    password_confirmation = params["password_confirmation"]

    if is_nil(user.hashed_password) do
      cond do
        is_nil(password) || String.length(password) < 12 ->
          {:noreply, put_flash(socket, :error, "Password must be at least 12 characters.")}

        password != password_confirmation ->
          {:noreply, put_flash(socket, :error, "Passwords do not match.")}

        true ->
          save_onboarding(socket, profile, user, params, password)
      end
    else
      save_onboarding(socket, profile, user, params, nil)
    end
  end

  defp save_onboarding(socket, profile, user, params, password) do
    user_attrs = %{
      first_name: params["first_name"],
      last_name: params["last_name"],
      phone: params["phone"]
    }

    profile_attrs = %{
      "display_name" => params["display_name"],
      "bio" => params["bio"],
      "age_range" => params["age_range"],
      "location" => params["location"],
      "sms_opt_in" => params["sms_opt_in"] == "true",
      "availability_preference" => params["availability_preference"],
      "agreed_to_terms" => params["agreed_to_terms"] == "true"
    }

    # Set password first if needed (without deleting session tokens)
    password_result =
      if password do
        user
        |> WorthAsking.Accounts.User.password_changeset(%{password: password})
        |> WorthAsking.Repo.update()
      else
        {:ok, user}
      end

    case password_result do
      {:ok, _updated_user} ->
        case Contributors.complete_onboarding(profile, profile_attrs, user, user_attrs) do
          {:ok, _profile} ->
            {:noreply,
             socket
             |> put_flash(:info, "Profile setup complete.")
             |> push_navigate(to: ~p"/contributors/guidelines")}

          {:error, changeset} ->
            {:noreply,
             socket
             |> put_flash(:error, "Please check the form and try again. #{inspect(changeset.errors)}")}
        end

      {:error, changeset} ->
        {:noreply, put_flash(socket, :error, "Password error: #{inspect(changeset.errors)}")}
    end
  end
end
