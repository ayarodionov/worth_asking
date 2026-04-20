defmodule WorthAskingWeb.Router do
  use WorthAskingWeb, :router

  import WorthAskingWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {WorthAskingWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Public routes (non-LiveView)
  scope "/", WorthAskingWeb do
    pipe_through :browser

    get "/", PageController, :home
    get "/advisors/join", AdvisorRegistrationController, :new
    post "/advisors/join", AdvisorRegistrationController, :create
  end

  # Public LiveView routes
  scope "/", WorthAskingWeb do
    pipe_through :browser

    live_session :public,
      on_mount: [{WorthAskingWeb.UserAuth, :mount_current_scope}],
      session: {WorthAskingWeb.UserAuth, :live_session_data, []} do
      live "/welcome", OnboardingLive
      live "/about", AboutLive
      live "/field-notes", FieldNotesLive
      live "/field-notes/:slug", FieldNoteShowLive
      live "/contributors/apply", ContributorApplyLive
      live "/contributors/:id", ContributorProfileLive
    end
  end

  # Stripe webhooks (no CSRF)
  scope "/webhooks", WorthAskingWeb do
    pipe_through :api

    post "/stripe", WebhookController, :stripe
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:worth_asking, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: WorthAskingWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", WorthAskingWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/users/register", UserRegistrationController, :new
    post "/users/register", UserRegistrationController, :create
  end

  # Authenticated user routes
  scope "/", WorthAskingWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/users/settings", UserSettingsController, :edit
    put "/users/settings", UserSettingsController, :update
    get "/users/settings/confirm-email/:token", UserSettingsController, :confirm_email

    # Stripe payment routes
    get "/stripe/checkout/:question_id", StripeController, :create_checkout
    get "/stripe/connect/onboarding", StripeController, :connect_onboarding
    get "/stripe/connect/return", StripeController, :connect_return

    live_session :authenticated,
      on_mount: [{WorthAskingWeb.UserAuth, :require_authenticated_user}] do
      live "/questions/new", QuestionLive
      live "/questions/:id", QuestionShowLive
      live "/my-questions", MyQuestionsLive
    end
  end

  # Contributor-only routes
  scope "/", WorthAskingWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :contributor,
      on_mount: [{WorthAskingWeb.UserAuth, :require_contributor}] do
      live "/contributors/onboarding", ContributorOnboardingLive
      live "/contributors/guidelines", ContributorGuidelinesLive
      live "/dashboard", ContributorDashboardLive
      live "/dashboard/respond/:question_id", ContributorResponseLive
    end
  end

  # Admin-only routes
  scope "/admin", WorthAskingWeb.Admin do
    pipe_through [:browser, :require_authenticated_user]

    live_session :admin,
      on_mount: [{WorthAskingWeb.UserAuth, :require_admin}] do
      live "/", AdminDashboardLive
      live "/reports", AdminReportsLive
      live "/applications", AdminApplicationsLive
    end
  end

  scope "/", WorthAskingWeb do
    pipe_through [:browser]

    get "/users/log-in", UserSessionController, :new
    get "/users/log-in/:token", UserSessionController, :confirm
    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end
end
