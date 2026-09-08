# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
mix setup           # Install deps, create DB, run migrations, build assets
mix phx.server      # Start dev server (localhost:4000)
iex -S mix phx.server  # Start server with interactive shell
mix test            # Run all tests
mix test path/to/test_file.exs  # Run a single test file
mix test --failed   # Re-run previously failed tests
mix precommit       # Run before committing: compile, check deps, format, test
mix format          # Format Elixir/HEEx code
mix ecto.migrate    # Run pending migrations
mix ecto.reset      # Drop, recreate, and seed DB
mix ecto.gen.migration name_with_underscores  # Generate a migration
mix assets.build    # Compile Tailwind CSS and JS (dev)
```

## Architecture

**WorthAsking** is a Phoenix 1.8 / LiveView app connecting people asking questions with paid expert contributors. Stack: Elixir, PostgreSQL, LiveView, Tailwind v4, esbuild. Deployed on Fly.io.

### Domain structure (`lib/worth_asking/`)

Business logic is organized into context modules:
- `accounts.ex` — user management and authentication (uses `phx.gen.auth` with `current_scope`)
- `questions.ex` — question/response/rating lifecycle
- `contributors.ex` — contributor profiles and approval flow
- `notifications.ex` — notification system with a background Worker
- `moderation.ex` — content blocking/flagging
- `admin.ex` — admin operations
- `categories.ex`, `field_notes.ex` — supporting features
- `mailer.ex` — email dispatch via Swoosh (Resend in production)

### Web structure (`lib/worth_asking_web/`)

- `router.ex` — route definitions; scopes use `live_session` for `current_scope` propagation
- `user_auth.ex` / `admin_auth.ex` — auth plugs (`:fetch_current_scope_for_user`, `:require_authenticated_user`, `:redirect_if_user_is_authenticated`)
- `live/` — LiveView modules (named with `Live` suffix, e.g. `QuestionLive`)
- `controllers/` — HTTP controllers
- `components/` — reusable function components

### Assets

- CSS: Tailwind v4 — no `tailwind.config.js`; uses `@import "tailwindcss"` syntax in `assets/css/app.css`
- JS: esbuild bundling; only `app.js` and `app.css` bundles are supported — import vendor deps into these, never use external `<script src>` tags
- Icons: `<.icon name="hero-x-mark">` from `core_components.ex` — never use `Heroicons` module directly

## Key conventions

**HTTP client**: Always use `:req` (`Req`). Never use `:httpoison`, `:tesla`, or `:httpc`.

**Auth / scope**: `phx.gen.auth` assigns `@current_scope`, not `@current_user`. Access the user as `@current_scope.user` in templates. Always pass `current_scope` as first arg to context functions.

**LiveView layouts**: Always begin LiveView templates with `<Layouts.app flash={@flash} current_scope={@current_scope}>`.

**Routing**: Routes needing auth go in a scope with `pipe_through [:browser, :require_authenticated_user]`. Never place authenticated routes in the public browser pipeline.

**`current_scope` errors**: Always caused by wrong `live_session` placement or missing `current_scope` assign — fix at the router, not in the LiveView.

**Forms**: Always use `to_form/2` in the LiveView and `<.form for={@form}>` / `<.input field={@form[:field]}>` in templates. Never access `@changeset` in templates.

**LiveView streams**: Use `stream/3` for collections, never regular list assigns for rendered collections. Streams are not enumerable — to filter, refetch and `reset: true`.

**Ecto migrations**: Always generate with `mix ecto.gen.migration` for correct timestamps. Schema fields use `:string` even for text columns.

**JS hooks**: Inline scripts in HEEx must use `:type={Phoenix.LiveView.ColocatedHook}` with a `.PrefixedName` — never raw `<script>` tags. External hooks go in `assets/js/` and are passed to `LiveSocket`.

**CSS**: Never use `@apply`. Write Tailwind classes directly. Never use daisyUI components — write custom Tailwind-based components.

**HEEx**: Use `{@assign}` for value interpolation in tag bodies and attributes. Use `<%= block_expr do %>` for `if`/`cond`/`case`/`for`. Never use `else if` — use `cond` or `case`.

**Elixir**: Never use index access (`list[i]`) on lists — use `Enum.at/2`. Never nest multiple modules in one file. Never use `String.to_atom/1` on user input.

## Environment variables (production)

- `DATABASE_URL` — PostgreSQL connection string
- `SECRET_KEY_BASE` — generate with `mix phx.gen.secret`
- `PHX_HOST` — hostname
- `PHX_SERVER=true` — required in releases
- `RESEND_API_KEY` — email sending (optional in dev, uses local mailbox)
