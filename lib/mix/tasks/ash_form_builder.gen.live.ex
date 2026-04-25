defmodule Mix.Tasks.AshFormBuilder.Gen.Live do
  @shortdoc "Scaffolds a full CRUD LiveView for an Ash resource (Cinder + AshFormBuilder)"

  @moduledoc """
  Scaffolds a complete, production-grade CRUD LiveView interface for the given
  Ash resource. Generates two files:

  - **`index.ex`** — Phoenix LiveView with mount, handle_params, handle_info, and
    handle_event for full CRUD. URL-state is managed by `Cinder.UrlSync`.
  - **`index.html.heex`** — HEEx template using `Cinder.collection` for the data
    table (filtering, sorting, pagination) and `AshFormBuilder.FormComponent` inside
    `<.modal>` for create/edit.

  ## Usage

      $ mix ash_form_builder.gen.live Accounts User
      $ mix ash_form_builder.gen.live Blog Post
      $ mix ash_form_builder.gen.live Inventory Product --page-size 50
      $ mix ash_form_builder.gen.live Accounts User --out lib/my_app_web/live/admin

  ## Arguments

    * `Context` — The Ash domain/context namespace (e.g. `Accounts`, `Blog`)
    * `Resource` — The resource module name within that context (e.g. `User`, `Post`)

  The full resource module is derived as `<AppModule>.<Context>.<Resource>`,
  e.g. `mix ash_form_builder.gen.live Accounts User` → `MyApp.Accounts.User`.

  ## Options

    * `--out` / `-o` — Override output directory.
      Default: `lib/<otp_app>_web/live/<snake_resource>_live`
    * `--page-size` / `-p` — Cinder page size. Default: `25`

  ## What is Generated

  ### index.ex

  ```elixir
  defmodule MyAppWeb.UserLive.Index do
    use MyAppWeb, :live_view
    use Cinder.UrlSync

    # mount/3          — initialises assigns (url_state: false, record: nil, form: nil)
    # handle_params/3  — delegates URL state to Cinder.UrlSync, routes live_actions
    # apply_action/3   — builds AshPhoenix.Form for :new and :edit, loads record for :edit
    # handle_info/2    — closes modal + refreshes Cinder table after form submit
    # handle_event/3   — "delete" handler with Cinder refresh
  end
  ```

  ### index.html.heex

  ```heex
  <.header>Users <:actions>New User</:actions></.header>

  <Cinder.collection id="user-collection" resource={MyApp.Accounts.User} ...>
    <:col .../>  <%!-- TODO: replace placeholder with real attributes --%>
    <:col label="Actions">Edit | Delete</:col>
  </Cinder.collection>

  <.modal :if={@live_action in [:new, :edit]} ...>
    <.live_component module={AshFormBuilder.FormComponent} form={@form} resource={...} />
  </.modal>
  ```

  ## Router Instructions

  The generator prints the exact `live` route entries to add to your `router.ex`.

  ## Customising Columns

  After generation, open `index.html.heex` and replace the placeholder `<:col>` with
  your resource's actual attributes:

      <:col :let={user} field="name"   filter sort>{user.name}</:col>
      <:col :let={user} field="email"  filter>{user.email}</:col>
      <:col :let={user} field="role"   filter={:select}>{user.role}</:col>

  Use `filter` for text filtering, `filter={:select}` for enum/select filtering,
  and `sort` to enable column sorting.
  """

  use Mix.Task
  import Mix.Generator

  @impl Mix.Task
  def run(argv) do
    {opts, args, _} =
      OptionParser.parse(argv,
        switches: [out: :string, page_size: :integer],
        aliases: [o: :out, p: :page_size]
      )

    case args do
      [context, resource_base] ->
        validate_names!(context, resource_base)
        generate(context, resource_base, opts)

      _ ->
        Mix.raise("""
        Expected exactly two arguments: Context and Resource.

        Usage:
          mix ash_form_builder.gen.live Context Resource [--out dir] [--page-size n]

        Examples:
          mix ash_form_builder.gen.live Accounts User
          mix ash_form_builder.gen.live Blog Post --page-size 50
        """)
    end
  end

  # ---------------------------------------------------------------------------
  # Validation
  # ---------------------------------------------------------------------------

  defp validate_names!(context, resource_base) do
    unless context =~ ~r/^[A-Z][A-Za-z0-9]*$/ do
      Mix.raise(
        "Context must start with an uppercase letter and contain only alphanumeric " <>
          "characters. Got: #{inspect(context)}"
      )
    end

    unless resource_base =~ ~r/^[A-Z][A-Za-z0-9]*$/ do
      Mix.raise(
        "Resource must start with an uppercase letter and contain only alphanumeric " <>
          "characters. Got: #{inspect(resource_base)}"
      )
    end

    if context == resource_base do
      Mix.shell().info([
        :yellow,
        "warning: Context and Resource have the same name (#{context}). " <>
          "This will produce a resource module like MyApp.#{context}.#{resource_base}. " <>
          "This is unusual — did you mean a different context name?",
        :reset
      ])
    end
  end

  # ---------------------------------------------------------------------------
  # Core generation
  # ---------------------------------------------------------------------------

  defp generate(context, resource_base, opts) do
    otp_app = infer_otp_app()
    app_module = infer_app_module(otp_app)
    web_module = "#{app_module}Web"
    resource_module = "#{app_module}.#{context}.#{resource_base}"
    live_module = "#{web_module}.#{resource_base}Live.Index"

    snake_resource = Macro.underscore(resource_base)
    # Simple pluralisation — developers can rename the route if needed
    route_segment = "#{snake_resource}s"
    collection_id = "#{snake_resource}-collection"
    human_name = humanize(resource_base)
    human_names = "#{human_name}s"
    human_name_lower = String.downcase(human_name)
    human_names_lower = String.downcase(human_names)

    page_size = Keyword.get(opts, :page_size, 25)
    default_out = "lib/#{otp_app}_web/live/#{snake_resource}_live"
    out_dir = Keyword.get(opts, :out, default_out)

    index_ex_path = Path.join(out_dir, "index.ex")
    index_heex_path = Path.join(out_dir, "index.html.heex")

    File.mkdir_p!(out_dir)

    create_file(
      index_ex_path,
      index_ex_content(
        live_module: live_module,
        web_module: web_module,
        resource_module: resource_module,
        resource_base: resource_base,
        snake_resource: snake_resource,
        route_segment: route_segment,
        collection_id: collection_id,
        human_name: human_name,
        human_names: human_names
      )
    )

    create_file(
      index_heex_path,
      index_heex_content(
        resource_module: resource_module,
        resource_base: resource_base,
        snake_resource: snake_resource,
        route_segment: route_segment,
        collection_id: collection_id,
        human_name: human_name,
        human_names: human_names,
        human_name_lower: human_name_lower,
        human_names_lower: human_names_lower,
        page_size: page_size
      )
    )

    print_instructions(web_module, resource_base, route_segment)
  end

  # ---------------------------------------------------------------------------
  # index.ex template
  # ---------------------------------------------------------------------------

  defp index_ex_content(a) do
    live_module = a[:live_module]
    web_module = a[:web_module]
    resource_module = a[:resource_module]
    resource_base = a[:resource_base]
    route_segment = a[:route_segment]
    collection_id = a[:collection_id]
    human_name = a[:human_name]
    human_names = a[:human_names]

    """
    defmodule #{live_module} do
      @moduledoc \"\"\"
      LiveView for listing, creating, and editing #{human_names}.

      ## Architecture

      - `Cinder.collection` renders a filterable, sortable, paginated table directly
        from `#{resource_module}` Ash queries. URL state (filters, sort, page) is kept
        in sync with the browser URL via `use Cinder.UrlSync`.

      - Create and edit forms live inside `<.modal>` components controlled by `:new`
        and `:edit` live_actions. `AshFormBuilder.FormComponent` renders the form and
        emits `{:form_submitted, #{resource_base}, result}` on success.

      - After a successful create/edit/delete, `Cinder.refresh_table/2` triggers an
        async re-query of the collection without a full page reload.
      \"\"\"

      use #{web_module}, :live_view
      # Injects handle_info/2 for {:table_state_change, id, state} and keeps the
      # browser URL in sync with Cinder filter/sort/pagination state.
      use Cinder.UrlSync

      alias #{resource_module}

      # The id passed to <Cinder.collection id={@collection_id}> in the template.
      @collection_id "#{collection_id}"

      # ---------------------------------------------------------------------------
      # Mount & params
      # ---------------------------------------------------------------------------

      @impl Phoenix.LiveView
      def mount(_params, _session, socket) do
        {:ok,
         assign(socket,
           page_title: "#{human_names}",
           # Initialise to false — Cinder.UrlSync.handle_params/3 populates it.
           url_state: false,
           record: nil,
           form: nil
         )}
      end

      @impl Phoenix.LiveView
      def handle_params(params, uri, socket) do
        # Must be called so @url_state is populated for <Cinder.collection url_state=...>.
        socket = Cinder.UrlSync.handle_params(params, uri, socket)
        {:noreply, apply_action(socket, socket.assigns.live_action, params)}
      end

      # ---------------------------------------------------------------------------
      # Live action routing
      # ---------------------------------------------------------------------------

      defp apply_action(socket, :index, _params) do
        assign(socket, page_title: "#{human_names}", record: nil, form: nil)
      end

      defp apply_action(socket, :new, _params) do
        form =
          AshPhoenix.Form.for_create(#{resource_base}, :create,
            actor: socket.assigns[:current_user]
          )
          |> to_form()

        assign(socket, page_title: "New #{human_name}", record: nil, form: form)
      end

      defp apply_action(socket, :edit, %{"id" => id}) do
        record = Ash.get!(#{resource_base}, id, actor: socket.assigns[:current_user])

        form =
          AshPhoenix.Form.for_update(record, :update,
            actor: socket.assigns[:current_user]
          )
          |> to_form()

        assign(socket, page_title: "Edit #{human_name}", record: record, form: form)
      end

      # ---------------------------------------------------------------------------
      # AshFormBuilder.FormComponent callback
      #
      # Sent by FormComponent (via send/2 to the parent LiveView process) after a
      # successful Ash action. Close the modal, flash success, and refresh the table.
      # ---------------------------------------------------------------------------

      @impl Phoenix.LiveView
      def handle_info({:form_submitted, #{resource_base}, _result}, socket) do
        {:noreply,
         socket
         |> put_flash(:info, "#{human_name} saved successfully.")
         |> Cinder.refresh_table(@collection_id)
         |> push_patch(to: ~p"/#{route_segment}")}
      end

      # NOTE: handle_info/2 for {:table_state_change, id, state} is automatically
      # injected by `use Cinder.UrlSync` above. Do not define it manually.

      # ---------------------------------------------------------------------------
      # Events
      # ---------------------------------------------------------------------------

      @impl Phoenix.LiveView
      def handle_event("delete", %{"id" => id}, socket) do
        # TODO: Add error handling for authorization failures or missing records.
        record = Ash.get!(#{resource_base}, id, actor: socket.assigns[:current_user])
        Ash.destroy!(record, actor: socket.assigns[:current_user])

        {:noreply,
         socket
         |> put_flash(:info, "#{human_name} deleted successfully.")
         |> Cinder.refresh_table(@collection_id)}
      end
    end
    """
  end

  # ---------------------------------------------------------------------------
  # index.html.heex template
  # ---------------------------------------------------------------------------

  defp index_heex_content(a) do
    resource_module = a[:resource_module]
    _resource_base = a[:resource_base]
    snake_resource = a[:snake_resource]
    route_segment = a[:route_segment]
    collection_id = a[:collection_id]
    human_name = a[:human_name]
    human_names = a[:human_names]
    human_name_lower = a[:human_name_lower]
    human_names_lower = a[:human_names_lower]
    page_size = a[:page_size]

    # Pre-build expressions that appear in the output with escaped interpolation.
    # These produce {user.id}, {user.name}, #{user}/edit etc. in the .heex file.
    record_id_expr = "{#{snake_resource}.id}"
    route_edit_expr = "~p\"/#{route_segment}/\#{#{snake_resource}}/edit\""

    form_id_expr =
      "if @record, do: \"#{snake_resource}-edit-\#{@record.id}\", else: \"#{snake_resource}-new\""

    """
    <.header>
      #{human_names}
      <:actions>
        <.link patch={~p"/#{route_segment}/new"}>
          <.button>New #{human_name}</.button>
        </.link>
      </:actions>
    </.header>

    <%!--
      Cinder.collection renders a full-featured data table backed by Ash queries.

      Key attributes:
        resource  – The Ash resource module to query
        actor     – Authorization actor (usually current_user)
        url_state – Populated by Cinder.UrlSync.handle_params/3 in handle_params/3;
                    keeps filters, sort, and pagination synced to the URL
        page_size – Default page size (can be overridden per user if Cinder is configured)

      Column slots (<:col>):
        field   – Ash attribute name (string). Used for filtering and sorting.
        filter  – Enable text filter. Use filter={:select} for enum/atom fields.
        sort    – Enable column sort toggle.
        search  – Include field in the global search (if search is configured).

      TODO: Replace the placeholder column below with your resource's actual attributes.

      Example columns:
        <:col :let={#{snake_resource}} field="name"       filter sort>{#{snake_resource}.name}</:col>
        <:col :let={#{snake_resource}} field="email"      filter>{#{snake_resource}.email}</:col>
        <:col :let={#{snake_resource}} field="status"     filter={:select}>{#{snake_resource}.status}</:col>
        <:col :let={#{snake_resource}} field="inserted_at" sort>{#{snake_resource}.inserted_at}</:col>
    --%>
    <Cinder.collection
      id="#{collection_id}"
      resource={#{resource_module}}
      actor={assigns[:current_user]}
      url_state={@url_state}
      page_size={#{page_size}}
      empty_message="No #{human_names_lower} found."
    >
      <%!-- TODO: Replace this placeholder column with your resource's real attributes. --%>
      <:col :let={#{snake_resource}} field="id" sort label="ID">
        <span class="font-mono text-xs text-gray-500 dark:text-gray-400">
          #{record_id_expr}
        </span>
      </:col>

      <:col :let={#{snake_resource}} label="Actions" class="w-px whitespace-nowrap">
        <div class="flex items-center gap-4">
          <.link
            patch={#{route_edit_expr}}
            class="text-sm font-medium text-blue-600 hover:text-blue-500
                   dark:text-blue-400 dark:hover:text-blue-300"
          >
            Edit
          </.link>
          <.link
            phx-click="delete"
            phx-value-id={#{snake_resource}.id}
            data-confirm="Delete this #{human_name_lower}? This cannot be undone."
            class="text-sm font-medium text-red-600 hover:text-red-500
                   dark:text-red-400 dark:hover:text-red-300"
          >
            Delete
          </.link>
        </div>
      </:col>
    </Cinder.collection>

    <%!--
      Modal for :new and :edit live_actions.

      - Only mounted when live_action is :new or :edit (`:if` removes it for :index).
      - on_cancel fires JS.patch back to the index route when the user presses Escape
        or clicks the backdrop, which triggers apply_action/3 → :index, clearing the form.
      - AshFormBuilder.FormComponent renders the full form from the resource's DSL
        (or auto-inferred fields). It calls send(self(), {:form_submitted, Resource, result})
        on success, handled by handle_info/2 in this LiveView.
    --%>
    <.modal
      :if={@live_action in [:new, :edit]}
      id="#{snake_resource}-modal"
      show
      on_cancel={JS.patch(~p"/#{route_segment}")}
    >
      <.live_component
        module={AshFormBuilder.FormComponent}
        id={#{form_id_expr}}
        resource={#{resource_module}}
        form={@form}
        submit_label={if @live_action == :new, do: "Create #{human_name}", else: "Save Changes"}
      />
    </.modal>
    """
  end

  # ---------------------------------------------------------------------------
  # Post-generation output
  # ---------------------------------------------------------------------------

  defp print_instructions(web_module, resource_base, route_segment) do
    live_module = "#{resource_base}Live.Index"
    col_width = max(String.length(route_segment) + 14, 24)

    Mix.shell().info("")

    Mix.shell().info([
      :cyan,
      "Add to your router.ex (inside your :browser scope):",
      :reset
    ])

    Mix.shell().info("")
    Mix.shell().info("  scope \"/\", #{web_module} do")
    Mix.shell().info("    pipe_through :browser")
    Mix.shell().info("")

    idx_route = "live \"/#{route_segment}\","
    new_route = "live \"/#{route_segment}/new\","
    edit_route = "live \"/#{route_segment}/:id/edit\","

    Mix.shell().info("    #{String.pad_trailing(idx_route, col_width)} #{live_module}, :index")

    Mix.shell().info("    #{String.pad_trailing(new_route, col_width)} #{live_module}, :new")

    Mix.shell().info("    #{String.pad_trailing(edit_route, col_width)} #{live_module}, :edit")

    Mix.shell().info("  end")
    Mix.shell().info("")
    Mix.shell().info([:yellow, "Next steps:", :reset])

    Mix.shell().info(
      "  1. Open index.html.heex and replace the placeholder <:col> with your resource's attributes."
    )

    Mix.shell().info(
      "  2. Ensure #{resource_base} has AshFormBuilder configured, or fields will be auto-inferred."
    )

    Mix.shell().info(
      "  3. Review actor/authorization — generated code uses assigns[:current_user]."
    )

    Mix.shell().info(
      "  4. The route \"/#{route_segment}\" uses simple pluralisation. " <>
        "Rename in router.ex if needed."
    )

    Mix.shell().info("")
  end

  # ---------------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------------

  defp infer_otp_app do
    Mix.Project.config()[:app]
    |> to_string()
    |> String.replace("-", "_")
  end

  defp infer_app_module(otp_app) do
    Macro.camelize(otp_app)
  end

  defp humanize(string) when is_binary(string) do
    string
    |> Macro.underscore()
    |> String.split("_")
    |> Enum.map_join(" ", &String.capitalize/1)
  end
end
