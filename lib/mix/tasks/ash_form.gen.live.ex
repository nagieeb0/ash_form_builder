defmodule Mix.Tasks.AshForm.Gen.Live do
  @shortdoc "Scaffolds a CRUD LiveView for an Ash resource (Cinder + AshFormBuilder)"

  @moduledoc """
  Scaffolds a complete CRUD LiveView interface for an Ash resource.

  ## Usage

      $ mix ash_form.gen.live -r MyApp.Accounts.User
      $ mix ash_form.gen.live --resource MyApp.Blog.Post --accent teal --transitions smooth
      $ mix ash_form.gen.live -r MyApp.Inventory.Product --page-size 50
      $ mix ash_form.gen.live -r MyApp.Accounts.User --out lib/my_app_web/live/admin

  ## Required option

    * `--resource` / `-r` — Fully-qualified resource module
      (e.g. `MyApp.Accounts.User`).

  ## Optional flags

    * `--out` / `-o` — Override output directory.
      Default: `lib/<otp_app>_web/live/<snake_resource>_live`
    * `--page-size` / `-p` — Cinder page size. Default: `25`
    * `--theme` / `-t` — Theme atom or module passed to the form
      component (`:shadcn`, `:default`, `:glassmorphism`, `:mishka`, or
      a user-registered atom). Defaults to whatever the resource's form
      DSL declares.
    * `--accent` — Accent color atom (e.g. `teal`, `indigo`, `rose`).
      Overrides the form's DSL default.
    * `--transitions` — `none`, `subtle`, or `smooth`.
    * `--web-module` — Override the `<App>Web` module name (rare).

  ## Generated files

  - **`index.ex`** — Phoenix LiveView with mount, handle_params,
    handle_info, and handle_event for create / edit / delete. URL state
    managed by `Cinder.UrlSync`.
  - **`index.html.heex`** — Cinder.collection table + `<.modal>` with
    `AshFormBuilder.FormComponent` for create/edit. Honors per-form
    `theme`/`accent`/`transitions` from the resource's DSL, with
    optional flag-based overrides.
  """

  use Mix.Task
  import Mix.Generator

  @impl Mix.Task
  def run(argv) do
    {opts, _args, _} =
      OptionParser.parse(argv,
        strict: [
          resource: :string,
          out: :string,
          page_size: :integer,
          theme: :string,
          accent: :string,
          transitions: :string,
          web_module: :string
        ],
        aliases: [r: :resource, o: :out, p: :page_size, t: :theme]
      )

    resource_module =
      Keyword.get(opts, :resource) ||
        Mix.raise("""
        Missing required `--resource` (`-r`) flag.

        Usage:
          mix ash_form.gen.live -r MyApp.Accounts.User
        """)

    validate_resource!(resource_module)
    generate(resource_module, opts)
  end

  # ---------------------------------------------------------------------------
  # Validation
  # ---------------------------------------------------------------------------

  defp validate_resource!(resource_module) do
    unless resource_module =~ ~r/^[A-Z][A-Za-z0-9]*(\.[A-Z][A-Za-z0-9]*)*$/ do
      Mix.raise(
        "Resource must be a fully-qualified module name like " <>
          "`MyApp.Accounts.User`. Got: #{inspect(resource_module)}"
      )
    end
  end

  # ---------------------------------------------------------------------------
  # Core generation
  # ---------------------------------------------------------------------------

  defp generate(resource_module, opts) do
    parts = String.split(resource_module, ".")
    app_module = List.first(parts)
    resource_base = List.last(parts)

    web_module = Keyword.get(opts, :web_module, "#{app_module}Web")
    live_module = "#{web_module}.#{resource_base}Live.Index"

    snake_resource = Macro.underscore(resource_base)
    route_segment = "#{snake_resource}s"
    collection_id = "#{snake_resource}-collection"
    human_name = humanize(resource_base)
    human_names = "#{human_name}s"
    human_name_lower = String.downcase(human_name)
    human_names_lower = String.downcase(human_names)

    page_size = Keyword.get(opts, :page_size, 25)
    otp_app = infer_otp_app(app_module)
    default_out = "lib/#{otp_app}_web/live/#{snake_resource}_live"
    out_dir = Keyword.get(opts, :out, default_out)

    bindings = [
      live_module: live_module,
      web_module: web_module,
      resource_module: resource_module,
      resource_base: resource_base,
      snake_resource: snake_resource,
      route_segment: route_segment,
      collection_id: collection_id,
      human_name: human_name,
      human_names: human_names,
      human_name_lower: human_name_lower,
      human_names_lower: human_names_lower,
      page_size: page_size,
      theme: Keyword.get(opts, :theme),
      accent: Keyword.get(opts, :accent),
      transitions: Keyword.get(opts, :transitions)
    ]

    File.mkdir_p!(out_dir)

    create_file(Path.join(out_dir, "index.ex"), index_ex_content(bindings))
    create_file(Path.join(out_dir, "index.html.heex"), index_heex_content(bindings))

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

      Uses the resource's auto-generated `Form` helper module
      (`#{resource_module}.Form`) to build create / update forms — no manual
      `AshPhoenix.Form` calls needed.

      `Cinder.collection` renders the data table directly from Ash queries.
      URL state (filters, sort, page) is kept in sync with the browser URL via
      `use Cinder.UrlSync`.

      The `:new` and `:edit` `live_action`s open `<.modal>` containing
      `AshFormBuilder.FormComponent`, which emits
      `{:form_submitted, #{resource_base}, result}` on success — handled below.
      \"\"\"

      use #{web_module}, :live_view
      use Cinder.UrlSync

      alias #{resource_module}

      @collection_id "#{collection_id}"

      # ---------------------------------------------------------------------------
      # Mount & params
      # ---------------------------------------------------------------------------

      @impl Phoenix.LiveView
      def mount(_params, _session, socket) do
        {:ok,
         assign(socket,
           page_title: "#{human_names}",
           url_state: false,
           record: nil,
           form: nil
         )}
      end

      @impl Phoenix.LiveView
      def handle_params(params, uri, socket) do
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
        form = #{resource_base}.Form.for_create(actor: socket.assigns[:current_user])
        assign(socket, page_title: "New #{human_name}", record: nil, form: form)
      end

      defp apply_action(socket, :edit, %{"id" => id}) do
        record = Ash.get!(#{resource_base}, id, actor: socket.assigns[:current_user])
        form = #{resource_base}.Form.for_update(record, actor: socket.assigns[:current_user])
        assign(socket, page_title: "Edit #{human_name}", record: record, form: form)
      end

      # ---------------------------------------------------------------------------
      # AshFormBuilder.FormComponent callback
      #
      # Emitted by FormComponent (via send/2) after a successful Ash action.
      # ---------------------------------------------------------------------------

      @impl Phoenix.LiveView
      def handle_info({:form_submitted, #{resource_base}, _result}, socket) do
        {:noreply,
         socket
         |> put_flash(:info, "#{human_name} saved successfully.")
         |> Cinder.refresh_table(@collection_id)
         |> push_patch(to: ~p"/#{route_segment}")}
      end

      # ---------------------------------------------------------------------------
      # Events
      # ---------------------------------------------------------------------------

      @impl Phoenix.LiveView
      def handle_event("delete", %{"id" => id}, socket) do
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
    snake_resource = a[:snake_resource]
    route_segment = a[:route_segment]
    collection_id = a[:collection_id]
    human_name = a[:human_name]
    human_names = a[:human_names]
    human_name_lower = a[:human_name_lower]
    human_names_lower = a[:human_names_lower]
    page_size = a[:page_size]

    record_id_expr = "{#{snake_resource}.id}"
    route_edit_expr = "~p\"/#{route_segment}/\#{#{snake_resource}}/edit\""

    form_id_expr =
      "if @record, do: \"#{snake_resource}-edit-\#{@record.id}\", else: \"#{snake_resource}-new\""

    component_attrs =
      [
        {:theme, a[:theme]},
        {:accent, a[:accent]},
        {:transitions, a[:transitions]}
      ]
      |> Enum.flat_map(fn
        {_k, nil} -> []
        {:theme, v} -> ["    theme={#{format_theme(v)}}"]
        {k, v} -> ["    #{k}={:#{v}}"]
      end)
      |> Enum.join("\n")

    component_attrs_block =
      if component_attrs == "", do: "", else: "\n" <> component_attrs

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

      Replace the placeholder column with your resource's real attributes:

        <:col :let={#{snake_resource}} field="name"  filter sort>{#{snake_resource}.name}</:col>
        <:col :let={#{snake_resource}} field="email" filter>{#{snake_resource}.email}</:col>
    --%>
    <Cinder.collection
      id="#{collection_id}"
      resource={#{resource_module}}
      actor={assigns[:current_user]}
      url_state={@url_state}
      page_size={#{page_size}}
      empty_message="No #{human_names_lower} found."
    >
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
                   dark:text-blue-400 dark:hover:text-blue-300 transition-colors duration-150"
          >
            Edit
          </.link>
          <.link
            phx-click="delete"
            phx-value-id={#{snake_resource}.id}
            data-confirm="Delete this #{human_name_lower}? This cannot be undone."
            class="text-sm font-medium text-red-600 hover:text-red-500
                   dark:text-red-400 dark:hover:text-red-300 transition-colors duration-150"
          >
            Delete
          </.link>
        </div>
      </:col>
    </Cinder.collection>

    <%!--
      Modal for :new and :edit live_actions.

      AshFormBuilder.FormComponent picks up per-form theme/accent/transitions
      declared in the resource's `forms do form :create do … end end` DSL.
      Override here by passing `theme={:shadcn}`, `accent={:teal}`, or
      `transitions={:smooth}`.
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
        submit_label={if @live_action == :new, do: "Create #{human_name}", else: "Save Changes"}#{component_attrs_block}
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
      "  2. Ensure #{resource_base} declares a `forms do … end` block (or fields will be auto-inferred)."
    )

    Mix.shell().info(
      "  3. Review actor/authorization — generated code uses assigns[:current_user]."
    )

    Mix.shell().info(
      "  4. The route \"/#{route_segment}\" uses simple pluralisation. Rename in router.ex if needed."
    )

    Mix.shell().info([
      :yellow,
      "  5. The generated index uses Cinder. Add `{:cinder, \"~> 0.12\"}` to your deps if it isn't already present.",
      :reset
    ])

    Mix.shell().info("")
  end

  # ---------------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------------

  defp infer_otp_app(_app_module) do
    Mix.Project.config()[:app]
    |> to_string()
    |> String.replace("-", "_")
  end

  defp format_theme(value) do
    # If it looks like a module (capitalized), pass as a module ref.
    # Otherwise quote it as an atom.
    if value =~ ~r/^[A-Z]/, do: value, else: ":#{value}"
  end

  defp humanize(string) when is_binary(string) do
    string
    |> Macro.underscore()
    |> String.split("_")
    |> Enum.map_join(" ", &String.capitalize/1)
  end
end
