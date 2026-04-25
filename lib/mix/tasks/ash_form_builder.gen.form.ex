defmodule Mix.Tasks.AshFormBuilder.Gen.Form do
  @shortdoc "Generates a Phoenix LiveView form for an Ash resource"

  @moduledoc """
  Generates a self-contained Phoenix LiveView (or LiveComponent) that renders
  an `AshFormBuilder.FormComponent` wired to the given Ash resource.

  ## Usage

      $ mix ash_form_builder.gen.form MyApp.Accounts.User
      $ mix ash_form_builder.gen.form MyApp.Accounts.User --action update
      $ mix ash_form_builder.gen.form MyApp.Accounts.User --out lib/my_app_web/live
      $ mix ash_form_builder.gen.form MyApp.Accounts.User --component

  ## Arguments

    * `Resource` — Fully-qualified Ash resource module (e.g. `MyApp.Accounts.User`)

  ## Options

    * `--action` / `-a` (default: `create`) — Ash action to generate the form for
    * `--out` / `-o` (default: `lib/<otp_app>_web/live`) — Output directory
    * `--component` / `-c` — Generate a LiveComponent instead of a LiveView

  ## Generated File

  For a LiveView, the generated file mounts `AshPhoenix.Form`, renders the
  `AshFormBuilder.FormComponent`, and handles the `{:form_submitted, ...}` message
  sent on success.

  For a LiveComponent, the generated file exposes an idiomatic `update/2` +
  `render/1` pair ready to drop into a parent LiveView.

  ## Example

      $ mix ash_form_builder.gen.form MyApp.Blog.Post --action create
      * created lib/my_app_web/live/post_form_live.ex

      Add to your router:
        live "/posts/new", MyAppWeb.PostFormLive

  """

  use Mix.Task

  import Mix.Generator

  @impl Mix.Task
  def run(argv) do
    {opts, args, _} =
      OptionParser.parse(argv,
        switches: [action: :string, out: :string, component: :boolean],
        aliases: [a: :action, o: :out, c: :component]
      )

    case args do
      [] ->
        Mix.raise("""
        Usage:
          mix ash_form_builder.gen.form MyApp.Resource [--action create] [--out lib/path] [--component]
        """)

      [resource_module | _] ->
        action = Keyword.get(opts, :action, "create")
        as_component = Keyword.get(opts, :component, false)

        otp_app = infer_otp_app()
        app_module = infer_app_module(resource_module)
        resource_base = resource_module |> String.split(".") |> List.last()
        snake_base = Macro.underscore(resource_base)

        out_dir = Keyword.get(opts, :out, "lib/#{otp_app}_web/live")
        file_name = "#{snake_base}_form_live.ex"
        file_path = Path.join(out_dir, file_name)

        view_module =
          if as_component do
            "#{app_module}Web.#{resource_base}FormComponent"
          else
            "#{app_module}Web.#{resource_base}FormLive"
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
  end

  # ---------------------------------------------------------------------------
  # Content generators
  # ---------------------------------------------------------------------------

  defp liveview_content(module, resource, action, resource_base, app_module) do
    """
    defmodule #{module} do
      use #{app_module}Web, :live_view

      @impl Phoenix.LiveView
      def mount(_params, _session, socket) do
        form = AshPhoenix.Form.for_#{action}(#{resource}, :#{action}) |> to_form()
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
    """
    defmodule #{module} do
      use #{app_module}Web, :live_component

      @impl Phoenix.LiveComponent
      def update(assigns, socket) do
        form = AshPhoenix.Form.for_#{action}(#{resource}, :#{action}) |> to_form()
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

  # ---------------------------------------------------------------------------
  # Introspection helpers
  # ---------------------------------------------------------------------------

  defp infer_otp_app do
    Mix.Project.config()[:app]
    |> to_string()
    |> String.replace("-", "_")
  end

  defp infer_app_module(resource_module) do
    # MyApp.Accounts.User → MyApp
    resource_module
    |> String.split(".")
    |> List.first()
  end
end
