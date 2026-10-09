---
name: phoenix
description: Gives the Phoenix 1.8 and LiveView rules and pitfalls for writing Elixir web code — HEEx templates, LiveView streams, hooks and forms, phx.gen.auth scopes and routes, and tests. Use when writing or reviewing Elixir, HEEx or LiveView code, adding a route, or debugging a missing `current_scope`.
---

# Phoenix 1.8

Your pretrained Phoenix knowledge is mostly older than 1.8; where it disagrees with this file, this file wins. Read the project's Phoenix and LiveView versions from `mix.lock` first. The project's own `AGENTS.md` or `CLAUDE.md` wins over this file.

Read the reference files when the work reaches them:

- [references/streams.md](references/streams.md) — before you render, filter, count or update a collection in a LiveView.
- [references/js-interop.md](references/js-interop.md) — before you write a `phx-hook`, a `<script>` in HEEx, or a `push_event`.
- [references/forms.md](references/forms.md) — before you build or change a form.

## Elixir

- Lists have no index access through the access syntax. `mylist[i]` is invalid; use `Enum.at/2`, pattern matching or `List`.
- Variables are immutable and can be rebound, but a rebind inside `if`, `case` or `cond` does not escape the block. Bind the result of the block:

      # INVALID: the rebind inside the `if` is lost
      if connected?(socket) do
        socket = assign(socket, :val, val)
      end

      # VALID
      socket =
        if connected?(socket) do
          assign(socket, :val, val)
        end

- Put one module in one file. Nested modules in one file can cause cyclic dependencies and compile errors.
- Structs do not implement `Access`, so `struct[:field]` fails. Use `struct.field`, or the struct's own API, such as `Ecto.Changeset.get_field/2` for a changeset.
- Use the standard library's `Time`, `Date`, `DateTime` and `Calendar` for dates and times. Add a dependency only when asked, or `date_time_parser` for parsing.
- Never call `String.to_atom/1` on user input: atoms are never collected, so it leaks memory.
- Name a predicate `thing?`, not `is_thing`. The `is_` prefix is for guards.
- OTP primitives such as `DynamicSupervisor` and `Registry` need a name in the child spec: `{DynamicSupervisor, name: MyApp.MyDynamicSup}`, then `DynamicSupervisor.start_child(MyApp.MyDynamicSup, child_spec)`.
- Use `Task.async_stream(collection, callback, options)` for concurrent enumeration with back-pressure, usually with `timeout: :infinity`.
- Use `Req` for HTTP requests. Phoenix includes it; avoid `:httpoison`, `:tesla` and `:httpc`.

## Ecto

- Preload every association a template reads, such as `message.user.email`.
- `seeds.exs` needs `import Ecto.Query` and the other modules it uses.
- A schema field for a `:text` column is `:string`: `field :name, :string`.
- `Ecto.Changeset.validate_number/2` has no `:allow_nil` option. Validations run only on a change that is not nil, so none is needed.
- Read a changeset's field with `Ecto.Changeset.get_field(changeset, :field)`.
- A field the code sets, such as `user_id`, stays out of `cast`, so a request cannot set it. Set it on the struct.
- Create a migration with `mix ecto.gen.migration name_with_underscores`, which writes the timestamp.

## Mix

- Read a task's docs and options with `mix help <task>` before you use it.
- To debug a failure, run one file, `mix test test/my_test.exs`, or the failed tests, `mix test --failed`.
- `mix deps.clean --all` is almost never needed.

## Tests

- Start processes with `start_supervised!/1`, which cleans them up between tests.
- Synchronise on messages, not on time. `Process.sleep/1` and `Process.alive?/1` make a test slow and flaky.
  - To wait for a process to finish, monitor it and assert on the `DOWN` message:

        ref = Process.monitor(pid)
        assert_receive {:DOWN, ^ref, :process, ^pid, :normal}

  - To wait until a process has handled earlier messages, call `_ = :sys.get_state(pid)`.

### LiveView tests

- Assert with `Phoenix.LiveViewTest` and `LazyHTML`. Drive forms with `render_submit/2` and `render_change/2`.
- Select the DOM ids the template gives its key elements, through `element/2` and `has_element?/2`: `assert has_element?(view, "#my-form")`. Assert on raw HTML or on text content only when nothing else shows the outcome.
- Test outcomes, not implementation details.
- Split large features into small test files: content first, then interaction.
- `Phoenix.Component` functions such as `<.form>` may render other HTML than you expect. Test against the HTML they render.
- To debug a selector, print the matches of the selector, not the whole page:

      html = render(view)
      document = LazyHTML.from_fragment(html)
      matches = LazyHTML.filter(document, "your-complex-selector")
      IO.inspect(matches, label: "Matches")

## Phoenix

- Begin every LiveView template with `<Layouts.app flash={@flash} ...>`, which wraps the content. `Layouts` is aliased in `my_app_web.ex`.
- `<.flash_group>` lives in `Layouts` and is called only from `layouts.ex`.
- Draw icons with the `<.icon name="hero-x-mark" class="w-5 h-5"/>` component from `core_components.ex`, never a `Heroicons` module.
- Use the imported `<.input>` component for form inputs. A `class` you pass replaces its default classes, so your classes must style the input fully.
- A router `scope` prefixes its alias to every route inside it, so a route needs no alias of its own:

      scope "/admin", AppWeb.Admin do
        pipe_through :browser

        live "/users", UserLive, :index   # AppWeb.Admin.UserLive
      end

- `Phoenix.View` is gone.
- Put app-wide template imports and aliases in the `html_helpers` block of `my_app_web.ex`.

### Assets

- Tailwind v4 needs no `tailwind.config.js`. Keep the import syntax in `app.css`:

      @import "tailwindcss" source(none);
      @source "../css";
      @source "../js";
      @source "../../lib/my_app_web";

- Never use `@apply` in raw CSS.
- Write your own Tailwind components instead of daisyUI components.
- Only the `app.js` and `app.css` bundles exist. Import a vendor dependency into them; a layout cannot link an outside script `src` or stylesheet `href`.
- Never write an inline `<script>` in a template. Use a colocated hook: see [references/js-interop.md](references/js-interop.md).

## Authentication and routes

`phx.gen.auth` assigns `current_scope`, not `current_user`. It creates:

- the plug `:fetch_current_scope_for_user`, in the default `:browser` pipeline;
- the plug `:require_authenticated_user`, which redirects to the log-in page without a user;
- `live_session :current_user`, for LiveViews that work with or without a user;
- `live_session :require_authenticated_user`, for LiveViews that need a user;
- the plug `redirect_if_user_is_authenticated`, for pages such as registration that only a visitor sees.

Rules:

- Handle the authentication flow in the router, with redirects.
- Read the user as `@current_scope.user` in templates and LiveViews.
- Pass `current_scope` to context functions as the first argument, and filter queries by `current_scope.user`.
- Each `live_session` name occurs once in the router. Add a route to the existing block.
- When you add a route, tell the user which scope, `live_session` and pipeline it is in, and why.
- A missing `current_scope` assign means the route is in the wrong `live_session`, or the template does not pass `current_scope` to `<Layouts.app>`. Fix the router or the call, not the symptom.

A LiveView that needs a user goes in the existing `:require_authenticated_user` block:

    scope "/", AppWeb do
      pipe_through [:browser, :require_authenticated_user]

      live_session :require_authenticated_user,
        on_mount: [{AppWeb.UserAuth, :require_authenticated}] do
        live "/users/settings", UserLive.Settings, :edit
        live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email
        live "/", MyLiveThatRequiresAuth, :index
      end
    end

A controller that needs a user goes in a scope that pipes through `:require_authenticated_user`:

    scope "/", AppWeb do
      pipe_through [:browser, :require_authenticated_user]

      get "/", MyControllerThatRequiresAuth, :index
    end

A LiveView that works with or without a user goes in the existing `:current_user` block. A controller in the `:browser` pipeline has `current_scope` already.

    scope "/", AppWeb do
      pipe_through [:browser]

      live_session :current_user,
        on_mount: [{AppWeb.UserAuth, :mount_current_scope}] do
        live "/", PublicLive
      end
    end

## HEEx

- Templates are `~H` or `.html.heex`.
- Build forms with `Phoenix.Component.form/1` and `inputs_for/1`: see [references/forms.md](references/forms.md).
- Give key elements, such as forms and buttons, a unique DOM id, so tests can select them.
- Elixir has no `else if`. Use `cond` or `case` for more than two branches:

      <%= cond do %>
        <% condition -> %>
          ...
        <% condition2 -> %>
          ...
        <% true -> %>
          ...
      <% end %>

- To show a literal `{` or `}`, for example code in a `<pre>` or `<code>`, put `phx-no-curly-interpolation` on the parent tag. Inside it, `<%= ... %>` still interpolates:

      <code phx-no-curly-interpolation>
        let obj = {key: "val"}
      </code>

- A `class` with more than one value is a list, and an `if` inside it takes parentheses:

      <a class={[
        "px-2 text-white",
        @some_flag && "py-5",
        if(@other_condition, do: "border-red-500", else: "border-blue-100")
      ]}>Text</a>

  Without the brackets, `class={"px-2", @flag && "py-5"}` is a compile error.
- Generate content with `<%= for item <- @collection do %>` or `:for`, never `Enum.each`.
- Comments are `<%!-- comment --%>`.
- Interpolate with `{...}` in attributes and for values in a tag body. Put block constructs (`if`, `cond`, `case`, `for`) in a tag body as `<%= ... %>`:

      <div id={@id}>
        {@my_assign}
        <%= if @some_block_condition do %>
          {@another_assign}
        <% end %>
      </div>

  `id="<%= @x %>"` and `{if ...}` / `{end}` are syntax errors.

## LiveView

- Navigate with `<.link navigate={href}>` and `<.link patch={href}>` in templates, and `push_navigate/2` and `push_patch/2` in a LiveView.
- Name a LiveView with a `Live` suffix, `AppWeb.WeatherLive`. The `:browser` scope is aliased to `AppWeb`, so the route is `live "/weather", WeatherLive`.
- Use a LiveComponent only for a strong, specific need. A function component covers most cases.
- Render a collection through a stream, not a list assign: see [references/streams.md](references/streams.md).

## Old patterns

These still compile in places but are deprecated:

- `live_redirect` and `live_patch` — use `<.link>`, `push_navigate/2` and `push_patch/2`.
- `phx-update="append"` and `phx-update="prepend"` — use a stream.
- `Phoenix.HTML.form_for` and `Phoenix.HTML.inputs_for` — use `<.form>` and `<.inputs_for>`.
- `~E` templates — use `~H`.
