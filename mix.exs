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
      
      Auto-generates Phoenix LiveView forms from Ash Framework resources. 
      Features: auto-inference, searchable/creatable combobox, nested forms, themes.
      
      EXPERIMENTAL: API may change. Use at your own risk.
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
  
  defp docs do
    [
      main: "AshFormBuilder",
      logo: "assets/logo.png",  # Add logo if available
      source_ref: "v#{@version}",
      source_url: @source_url,
      extras: [
        "README.md",
        "CHANGELOG.md",
        "guides/todo_app_integration.exs",
        "guides/relationships_guide.exs",
        "example_usage.ex",
        "lib/ash_form_builder/docs.ex",
        "lib/ash_form_builder/guide/installation.ex",
        "lib/ash_form_builder/guide/customization.ex",
        "lib/ash_form_builder/guide/fields.ex"
      ],
      groups_for_extras: [
        Guides: [
          "lib/ash_form_builder/guide/installation.ex",
          "lib/ash_form_builder/guide/customization.ex",
          "lib/ash_form_builder/guide/fields.ex",
          "guides/todo_app_integration.exs",
          "guides/relationships_guide.exs"
        ],
        Examples: [
          "example_usage.ex"
        ]
      ],
      groups_for_modules: [
        "Core Modules": [
          AshFormBuilder,
          AshFormBuilder.FormComponent,
          AshFormBuilder.FormRenderer,
          AshFormBuilder.Infer,
          AshFormBuilder.Info,
          AshFormBuilder.Field,
          AshFormBuilder.NestedForm
        ],
        Themes: [
          AshFormBuilder.Theme,
          AshFormBuilder.Theme.MishkaTheme,
          AshFormBuilder.Themes.Default
        ],
        Guides: [
          AshFormBuilder.Guide.Installation,
          AshFormBuilder.Guide.Customization,
          AshFormBuilder.Guide.Fields
        ],
        Transformers: [
          AshFormBuilder.Transformers.GenerateFormModule,
          AshFormBuilder.Transformers.ResolveNestedResources
        ]
      ],
      before_closing_body_tag: &before_closing_body_tag/1,
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"]
    ]
  end
  
  defp before_closing_body_tag(:html) do
    """
    <script src="https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js"></script>
    <script>
      document.addEventListener("DOMContentLoaded", function () {
        mermaid.initialize({
          startOnLoad: false,
          theme: document.body.className.includes("dark") ? "dark" : "default"
        });
        let id = 0;
        for (const codeBlock of document.querySelectorAll('pre code.language-mermaid')) {
          const pre = codeBlock.parentNode;
          const id = `mermaid-${id++}`;
          const graphDefinition = codeBlock.textContent;
          const graphDiv = document.createElement('div');
          graphDiv.id = id;
          pre.parentNode.insertBefore(graphDiv, pre);
          pre.remove();
          mermaid.render(id, graphDefinition).then(({svg}) => {
            graphDiv.innerHTML = svg;
          });
        }
      });
    </script>
    <style>
      /* Custom documentation styles */
      body {
        font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      }
      .content-inner {
        max-width: 1400px;
      }
      pre code {
        border-radius: 6px;
      }
      /* Warning box styles */
      .warning-box {
        background-color: #fff3cd;
        border-left: 4px solid #ffc107;
        padding: 1rem;
        margin: 1rem 0;
        border-radius: 4px;
      }
      .warning-box strong {
        color: #856404;
      }
      /* Guide navigation */
      .guide-nav {
        background: #f8f9fa;
        padding: 1rem;
        border-radius: 6px;
        margin: 1rem 0;
      }
      .guide-nav h3 {
        margin-top: 0;
      }
      .guide-nav ul {
        list-style: none;
        padding-left: 0;
      }
      .guide-nav li {
        margin: 0.5rem 0;
      }
    </style>
    """
  end
  
  defp before_closing_body_tag(_), do: ""
  
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
