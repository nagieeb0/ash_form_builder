defmodule Mix.Tasks.AshForm.Gen.Form do
  @shortdoc "Generates a Phoenix LiveView form for an Ash resource"

  @moduledoc """
  Generates a self-contained Phoenix LiveView (or LiveComponent) that renders
  an `AshFormBuilder.FormComponent` wired to the given Ash resource.

  ## Usage

      $ mix ash_form.gen.form -r MyApp.Accounts.User
      $ mix ash_form.gen.form -r MyApp.Accounts.User --action update
      $ mix ash_form.gen.form -r MyApp.Accounts.User --out lib/my_app_web/live
      $ mix ash_form.gen.form -r MyApp.Accounts.User --component

  ## Required option

    * `--resource` / `-r` — Fully-qualified resource module
      (e.g. `MyApp.Accounts.User`).

  ## Optional flags

    * `--action` / `-a` — Ash action to generate the form for
      (default: `create`).
    * `--out` / `-o` — Output directory
      (default: `lib/<otp_app>_web/live`).
    * `--component` / `-c` — Generate a LiveComponent instead of a LiveView.

  ## Generated file

  For a LiveView, the generated file calls the resource's
  `Resource.Form.for_<action>` helper, renders the
  `AshFormBuilder.FormComponent`, and handles the `{:form_submitted, ...}`
  message sent on success.

  For a LiveComponent, the generated file exposes an idiomatic `update/2` +
  `render/1` pair ready to drop into a parent LiveView.
  """

  use Mix.Task

  import Mix.Generator

  @impl Mix.Task
  def run(argv) do
    {opts, _args, _} =
      OptionParser.parse(argv,
        strict: [
          resource: :string,
          action: :string,
          out: :string,
          component: :boolean
        ],
        aliases: [r: :resource, a: :action, o: :out, c: :component]
      )

    resource_module =
      Keyword.get(opts, :resource) ||
        Mix.raise("""
        Missing required `--resource` (`-r`) flag.

        Usage:
          mix ash_form.gen.form -r MyApp.Accounts.User
        """)

    action = Keyword.get(opts, :action, "create")
    as_component = Keyword.get(opts, :component, false)

    otp_app = infer_otp_app()
    parts = String.split(resource_module, ".")
    app_module = List.first(parts)
    resource_base = List.last(parts)
    snake_base = Macro.underscore(resource_base)

    out_dir = Keyword.get(opts, :out, "lib/#{otp_app}_web/live")

    # When the action is anything other than the default `:create`, suffix
    # both the file and module name so we can scaffold separate LiveViews
    # per action (`gen.crud` invokes us once per declared form action).
    action_suffix =
      case action do
        "create" -> ""
        other -> "_#{Macro.underscore(other)}"
      end

    file_name = "#{snake_base}#{action_suffix}_form_live.ex"
    file_path = Path.join(out_dir, file_name)

    module_action_suffix =
      case action do
        "create" -> ""
        other -> Macro.camelize(other)
      end

    view_module =
      if as_component do
        "#{app_module}Web.#{resource_base}#{module_action_suffix}FormComponent"
      else
        "#{app_module}Web.#{resource_base}#{module_action_suffix}FormLive"
      end

    File.mkdir_p!(out_dir)

    content =
      if as_component do
        component_content(view_module, resource_module, action, resource_base, app_module)
      else
        liveview_content(view_module, resource_module, action, resource_base, app_module)
      end

    create_file(file_path, content)

    Mix.shell().info("")

    if as_component do
      Mix.shell().info([:cyan, "Add to a parent LiveView template:", :reset])
      Mix.shell().info("  <.live_component")
      Mix.shell().info("    module={#{view_module}}")
      Mix.shell().info("    id=\"#{snake_base}-form\"")
      Mix.shell().info("  />")
    else
      Mix.shell().info([:cyan, "Add to your router.ex:", :reset])
      Mix.shell().info("  live \"/#{snake_base}s/new\", #{view_module}")
    end

    Mix.shell().info("")
  end

  # ---------------------------------------------------------------------------
  # Content generators
  # ---------------------------------------------------------------------------

  defp liveview_content(module, resource, action, resource_base, app_module) do
    helper = helper_for(action)

    """
    defmodule #{module} do
      use #{app_module}Web, :live_view

      alias #{resource}

      @impl Phoenix.LiveView
      def mount(_params, _session, socket) do
        form = #{resource_base}.Form.#{helper}
        {:ok, assign(socket, form: form, page_title: "New #{resource_base}")}
      end

      @impl Phoenix.LiveView
      def render(assigns) do
        ~H\"""
        <div class="max-w-2xl mx-auto py-10 px-4 sm:px-6">
          <h1 class="text-2xl font-bold mb-8">{@page_title}</h1>

          <.live_component
            module={AshFormBuilder.FormComponent}
            id="#{Macro.underscore(resource_base)}-form"
            resource={#{resource}}
            form={@form}
          />
        </div>
        \"""
      end

      @impl Phoenix.LiveView
      def handle_info({:form_submitted, #{resource}, _result}, socket) do
        {:noreply, push_navigate(socket, to: "/")}
      end
    end
    """
  end

  defp component_content(module, resource, action, resource_base, app_module) do
    helper = helper_for(action)

    """
    defmodule #{module} do
      use #{app_module}Web, :live_component

      alias #{resource}

      @impl Phoenix.LiveComponent
      def update(assigns, socket) do
        form = #{resource_base}.Form.#{helper}
        {:ok, assign(socket, assigns) |> assign(form: form)}
      end

      @impl Phoenix.LiveComponent
      def render(assigns) do
        ~H\"""
        <div>
          <.live_component
            module={AshFormBuilder.FormComponent}
            id="#{Macro.underscore(resource_base)}-form"
            resource={#{resource}}
            form={@form}
          />
        </div>
        \"""
      end

      @impl Phoenix.LiveComponent
      def handle_info({:form_submitted, #{resource}, _result}, socket) do
        send(self(), {:#{Macro.underscore(resource_base)}_saved})
        {:noreply, socket}
      end
    end
    """
  end

  # The `for_<action>` helpers are only generated for the four standard
  # action names. Anything else falls back to `for_action(:custom_name)`.
  defp helper_for(action) when action in ~w(create read), do: "for_#{action}()"

  defp helper_for(action) when action in ~w(update destroy),
    do: "for_#{action}(record)"

  defp helper_for(action), do: "for_action(:#{action})"

  # ---------------------------------------------------------------------------
  # Introspection helpers
  # ---------------------------------------------------------------------------

  defp infer_otp_app do
    Mix.Project.config()[:app]
    |> to_string()
    |> String.replace("-", "_")
  end
end
