defmodule AshFormBuilder.MixProject do
  use Mix.Project

  def project do
    [
      app: :ash_form_builder,
      version: "0.1.0",
      elixir: "~> 1.17",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Hex.pm Package Configuration
      description: """
      ⚠️  EXPERIMENTAL - Use at Your Own Risk ⚠️

      AshFormBuilder is a Spark DSL extension for Ash Framework that automatically
      generates Phoenix LiveView forms from resource definitions with "Invisible UI"
      philosophy.

      Features:
      • Auto-inference engine for form fields from Ash actions
      • Many-to-many relationship support with searchable combobox
      • ✨ NEW: Creatable combobox - create related records on-the-fly
      • has_many nested forms with dynamic add/remove
      • Theme system (Default + MishkaChelekom adapters)
      • Domain Code Interface integration
      • Zero-boilerplate form generation

      This package is EXPERIMENTAL and under active development.
      API may change without notice. Use in production at your own risk.
      """,

      package: package(),

      # Docs
      name: "AshFormBuilder",
      source_url: "https://github.com/nagieeb0/ash_form_builder",
      homepage_url: "https://github.com/nagieeb0/ash_form_builder"
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:spark, "~> 2.0"},
      {:ash, "~> 3.0"},
      {:ash_phoenix, "~> 2.0"},
      {:phoenix_live_view, "~> 1.0"},
      {:phoenix, "~> 1.7"},
      {:phoenix_html, "~> 4.0"},
      {:mishka_chelekom, "~> 0.0.8"},

      # Dev dependencies
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:ecto_sql, "~> 3.10", only: :test},
      {:postgrex, ">= 0.0.0", only: :test}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/nagieeb0/ash_form_builder",
        "Ash Framework" => "https://hexdocs.pm/ash"
      },
      files: ~w(
        lib
        mix.exs
        README.md
        LICENSE
        CHANGELOG.md
        guides
        example_usage.ex
      ),
      maintainers: ["Nagieeb"],
      # Experimental warning in package metadata
      build_tools: ["mix"],
      requirements: [
        {:spark, "~> 2.0"},
        {:ash, "~> 3.0"},
        {:ash_phoenix, "~> 2.0"},
        {:phoenix_live_view, "~> 1.0"},
        {:phoenix, "~> 1.7"},
        {:phoenix_html, "~> 4.0"}
      ]
    ]
  end
end
