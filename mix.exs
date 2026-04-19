defmodule AshFormBuilder.MixProject do
  use Mix.Project

  @source_url "https://github.com/nagieeb0/ash_form_builder"
  @version "0.2.3"

  def project do
    [
      app: :ash_form_builder,
      version: @version,
      elixir: "~> 1.17",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),

      # Hex.pm Package Configuration
      description: description(),
      package: package(),

      # Project Information
      name: "AshFormBuilder",
      source_url: @source_url,
      homepage_url: "https://github.com/nagieeb0/ash_form_builder"
    ]
  end

  defp description do
    """
    AshFormBuilder = AshPhoenix.Form + Auto UI + Smart Components + Themes.

    Declarative form engine for Ash Framework with zero-config field inference,
    searchable/creatable combobox, nested forms, and pluggable theme system.
    """
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      # Core Dependencies
      {:spark, "~> 2.0"},
      {:ash, "~> 3.0"},
      {:ash_phoenix, "~> 2.0"},
      {:phoenix_live_view, "~> 1.0"},
      {:phoenix, "~> 1.7"},
      {:phoenix_html, "~> 4.0"},
      {:buckets, "~> 1.1"},

      # Optional: UI Component Libraries
      {:mishka_chelekom, "~> 0.0.8", optional: true},

      # Dev Dependencies
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:ecto_sql, "~> 3.10", only: :test},
      {:postgrex, ">= 0.0.0", only: :test},
      {:ash_postgres, "~> 2.0", only: :test},
      {:lazy_html, ">= 0.1.0", only: :test}
    ]
  end

  defp docs do
    [
      main: "readme",
      title: "AshFormBuilder v#{@version}",
      source_ref: "v#{@version}",
      source_url: @source_url,
      authors: ["Nagieeb"],
      extras: [
        "README.md",
        "CHANGELOG.md",
        "FILE_UPLOAD_GUIDE.md",
        "STORAGE_CONFIGURATION.md",
        "guides/theme_customization_guide.md",
        "guides/todo_app_integration.livemd",
        "guides/relationships_guide.livemd"
      ],
      groups_for_extras: [
        "": ["README.md", "CHANGELOG.md", "FILE_UPLOAD_GUIDE.md", "STORAGE_CONFIGURATION.md"],
        Guides: ["guides/theme_customization_guide.md", "guides/todo_app_integration.livemd", "guides/relationships_guide.livemd"]
      ],
      groups_for_modules: [
        "Core API": [
          AshFormBuilder,
          AshFormBuilder.FormComponent,
          AshFormBuilder.FormRenderer,
          AshFormBuilder.Infer,
          AshFormBuilder.Info
        ],
        "Data Structures": [
          AshFormBuilder.Field,
          AshFormBuilder.NestedForm
        ],
        Themes: [
          AshFormBuilder.Theme,
          AshFormBuilder.Theme.MishkaTheme,
          AshFormBuilder.Themes.Default,
          AshFormBuilder.Themes.Glassmorphism,
          AshFormBuilder.Themes.Shadcn
        ],
        Internal: [
          AshFormBuilder.Transformers.GenerateFormModule,
          AshFormBuilder.Transformers.ResolveNestedResources
        ]
      ],
      source_url: @source_url,
      formatters: ["html", "epub"],
      skip_undefined_reference_warnings_on: ["CHANGELOG.md", "README.md"]
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Hex" => "https://hex.pm/packages/ash_form_builder",
        "Ash Framework" => "https://hexdocs.pm/ash",
        "Phoenix LiveView" => "https://hexdocs.pm/phoenix_live_view"
      },
      files: [
        "lib",
        "mix.exs",
        "README.md",
        "CHANGELOG.md",
        "LICENSE",
        "guides",
        "example_usage.ex"
      ],
      maintainers: ["Nagieeb"],
      build_tools: ["mix"],
      requirements: [
        spark: [
          app: :spark,
          requirement: "~> 2.0",
          optional: false
        ],
        ash: [
          app: :ash,
          requirement: "~> 3.0",
          optional: false
        ],
        ash_phoenix: [
          app: :ash_phoenix,
          requirement: "~> 2.0",
          optional: false
        ],
        phoenix_live_view: [
          app: :phoenix_live_view,
          requirement: "~> 1.0",
          optional: false
        ],
        phoenix: [
          app: :phoenix,
          requirement: "~> 1.7",
          optional: false
        ],
        phoenix_html: [
          app: :phoenix_html,
          requirement: "~> 4.0",
          optional: false
        ],
        mishka_chelekom: [
          app: :mishka_chelekom,
          requirement: "~> 0.0.8",
          optional: true
        ]
      ]
    ]
  end
end
