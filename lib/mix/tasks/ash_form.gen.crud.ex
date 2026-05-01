defmodule Mix.Tasks.AshForm.Gen.Crud do
  @shortdoc "Scaffolds a Cinder-backed CRUD index plus standalone form LiveViews for an Ash resource"

  @moduledoc """
  One-shot CRUD scaffold for an Ash resource.

  Wraps `mix ash_form.gen.live` (Cinder data table + modal create/edit) and
  optionally `mix ash_form.gen.form` (one standalone form LiveView per
  declared form action) so a single command produces every page wired to
  `AshFormBuilder.FormComponent`.

  The form pages are *derived from the resource* — for each `forms do
  form :action do … end end` declaration on the resource the task generates
  one `<Resource>FormLive_<Action>` LiveView. Adding/removing actions on
  the resource will reshape what the next regeneration produces.

  ## Usage

      $ mix ash_form.gen.crud -r MyApp.Accounts.User
      $ mix ash_form.gen.crud -r MyApp.Blog.Post --accent teal --transitions smooth
      $ mix ash_form.gen.crud -r MyApp.Inventory.Product --no-standalone-forms
      $ mix ash_form.gen.crud -r MyApp.Accounts.User --actions create,update

  ## Required option

    * `--resource` / `-r` — Fully-qualified resource module
      (e.g. `MyApp.Accounts.User`).

  ## Optional flags

    * `--out` / `-o` — Output directory for the index LiveView.
      Default: `lib/<otp_app>_web/live/<snake_resource>_live`.
    * `--page-size` / `-p` — Cinder page size. Default: `25`.
    * `--theme` / `-t` — Theme atom or module (`:shadcn`, `:default`, …).
    * `--accent` — Accent color atom (`teal`, `indigo`, `rose`, …).
    * `--transitions` — `none`, `subtle`, or `smooth`.
    * `--web-module` — Override the `<App>Web` module name.
    * `--actions` — Comma-separated subset of actions to scaffold standalone
      form LiveViews for (default: every form declared by the resource).
    * `--no-standalone-forms` — Skip the per-action standalone form
      LiveViews; only generate the Cinder index page.

  ## Generated files

  - `index.ex` and `index.html.heex` (via `gen.live`) — listing page with
    Cinder data table and an in-page modal for create/edit.
  - One `<Resource>FormLive_<Action>` standalone LiveView per declared
    action (via `gen.form`) — useful for routes that link to a dedicated
    form page rather than the index modal.

  After generation the task prints router instructions for both the index
  page and any standalone form pages.
  """

  use Mix.Task

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
          web_module: :string,
          actions: :string,
          standalone_forms: :boolean
        ],
        aliases: [r: :resource, o: :out, p: :page_size, t: :theme]
      )

    resource_module =
      Keyword.get(opts, :resource) ||
        Mix.raise("""
        Missing required `--resource` (`-r`) flag.

        Usage:
          mix ash_form.gen.crud -r MyApp.Accounts.User
        """)

    # Ensure the project is compiled and its modules are on the code path
    # so we can introspect the resource's `forms do … end` declarations.
    # `loadpaths` adds every dependency to the BEAM code path, but does
    # *not* include the host project's own `ebin` — so we add it
    # explicitly after compiling.
    Mix.Task.run("loadpaths", [])
    Mix.Task.run("compile", [])

    ebin_path =
      Mix.Project.build_path()
      |> Path.join("lib/#{Mix.Project.config()[:app]}/ebin")
      |> String.to_charlist()

    Code.append_path(ebin_path)

    Mix.shell().info([
      :bright,
      :cyan,
      "==> Generating Cinder index for #{resource_module}",
      :reset
    ])

    Mix.Tasks.AshForm.Gen.Live.run(forward_live_args(opts))

    if Keyword.get(opts, :standalone_forms, true) do
      generate_standalone_forms(resource_module, opts)
    else
      Mix.shell().info([
        :yellow,
        "(Skipping standalone form LiveViews — --no-standalone-forms)",
        :reset
      ])
    end

    print_summary()
  end

  # ---------------------------------------------------------------------------
  # Standalone form LiveViews
  # ---------------------------------------------------------------------------

  defp generate_standalone_forms(resource_module, opts) do
    actions = resolve_actions(resource_module, opts)

    if actions == [] do
      Mix.shell().info([
        :yellow,
        "No form actions found on #{resource_module} — declare a `forms do form :action do … end end` block to scaffold standalone forms.",
        :reset
      ])
    else
      Enum.each(actions, fn action ->
        Mix.shell().info([
          :bright,
          :cyan,
          "==> Generating standalone form for action :#{action}",
          :reset
        ])

        Mix.Tasks.AshForm.Gen.Form.run(forward_form_args(resource_module, action, opts))
      end)
    end
  end

  defp resolve_actions(resource_module, opts) do
    case Keyword.get(opts, :actions) do
      nil ->
        introspect_form_actions(resource_module)

      "" ->
        introspect_form_actions(resource_module)

      raw when is_binary(raw) ->
        raw
        |> String.split(",", trim: true)
        |> Enum.map(&String.to_existing_atom(String.trim(&1)))
    end
  end

  # Best-effort introspection: only works when the resource has been
  # compiled (i.e. it lives in this project). Falls back to [] otherwise.
  defp introspect_form_actions(resource_module) do
    # Module.concat/1 is the safe path for converting a fully-qualified
    # module string into an atom — it leans on the BEAM atom table for
    # already-loaded modules and avoids the unbounded String.to_atom/1
    # behaviour that opens DoS vectors on user input.
    module = Module.concat([resource_module])

    Code.ensure_loaded(AshFormBuilder.Info)

    try do
      Code.ensure_compiled!(module)

      module
      |> AshFormBuilder.Info.forms()
      |> Enum.map(& &1.action)
    rescue
      e ->
        Mix.shell().info([
          :yellow,
          "Could not introspect #{resource_module} (#{Exception.message(e)}) — ",
          "pass `--actions create,update` to scaffold standalone form LiveViews explicitly.",
          :reset
        ])

        []
    end
  end

  # ---------------------------------------------------------------------------
  # Argument forwarding
  # ---------------------------------------------------------------------------

  defp forward_live_args(opts) do
    [
      flag(opts, :resource, "--resource"),
      flag(opts, :out, "--out"),
      flag(opts, :page_size, "--page-size"),
      flag(opts, :theme, "--theme"),
      flag(opts, :accent, "--accent"),
      flag(opts, :transitions, "--transitions"),
      flag(opts, :web_module, "--web-module")
    ]
    |> List.flatten()
  end

  defp forward_form_args(resource_module, action, opts) do
    [
      ["--resource", resource_module, "--action", to_string(action)],
      flag(opts, :out, "--out")
    ]
    |> List.flatten()
  end

  defp flag(opts, key, name) do
    case Keyword.get(opts, key) do
      nil -> []
      value -> [name, to_string(value)]
    end
  end

  defp print_summary do
    Mix.shell().info("")

    Mix.shell().info([
      :green,
      "Done. The Cinder index handles list/create/edit/delete in one page; ",
      :reset
    ])

    Mix.shell().info([
      :green,
      "the standalone form LiveViews give you dedicated routes per action.",
      :reset
    ])

    Mix.shell().info("")
  end
end
