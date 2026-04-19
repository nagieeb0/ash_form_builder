defmodule AshFormBuilder.Guide.Installation do
  @moduledoc """
  # Installation Guide

  Step-by-step installation instructions for AshFormBuilder.

  ## Contents

  1. [Prerequisites](#module-prerequisites)
  2. [Add Dependency](#module-add-dependency)
  3. [Configure Theme](#module-configure-theme)
  4. [Setup Ash Resources](#module-setup-ash-resources)
  5. [Verify Installation](#module-verify-installation)
  6. [Troubleshooting](#module-troubleshooting)

  ---

  ## Prerequisites

  Before installing AshFormBuilder, ensure you have:

  - ✅ **Elixir** ~> 1.17
  - ✅ **Phoenix** ~> 1.7
  - ✅ **Phoenix LiveView** ~> 1.0
  - ✅ **Ash Framework** ~> 3.0
  - ✅ **AshPhoenix** ~> 2.0

  If you don't have Ash Framework set up yet, follow the [Ash Framework Getting Started Guide](https://hexdocs.pm/ash/getting-started.html).

  ---

  ## Add Dependency

  ### Step 1: Update mix.exs

  Add `ash_form_builder` to your dependencies:

  ```elixir
  defp deps do
    [
      # Core Ash Framework
      {:ash, "~> 3.0"},
      {:ash_phoenix, "~> 2.0"},
      
      # Phoenix
      {:phoenix, "~> 1.7"},
      {:phoenix_live_view, "~> 1.0"},
      {:phoenix_html, "~> 4.0"},
      
      # ⭐ AshFormBuilder (EXPERIMENTAL)
      {:ash_form_builder, "~> 0.1.0"},
      
      # Optional: UI Component Libraries
      {:mishka_chelekom, "~> 0.0.8"}  # For MishkaTheme
    ]
  end
  ```

  ### Step 2: Fetch Dependencies

  ```bash
  mix deps.get
  ```

  ### Step 3: Compile

  ```bash
  mix compile
  ```

  ---

  ## Configure Theme

  AshFormBuilder uses a theme system for UI rendering. Choose one:

  ### Option 1: Default Theme (Recommended for Getting Started)

  No additional dependencies required.

  ```elixir
  # config/config.exs
  config :ash_form_builder, :theme, AshFormBuilder.Themes.Default
  ```

  **Characteristics:**
  - Semantic HTML5
  - Minimal CSS classes
  - Framework-agnostic
  - Easy to customize

  ### Option 2: MishkaChelekom Theme

  Requires the mishka_chelekom package.

  ```elixir
  # config/config.exs
  config :ash_form_builder, :theme, AshFormBuilder.Theme.MishkaTheme
  ```

  **Additional Setup:**

  1. Ensure mishka_chelekom is in deps:
     ```elixir
     {:mishka_chelekom, "~> 0.0.8"}
     ```

  2. Generate required components:
     ```bash
     mix mishka.ui.gen.component text_field
     mix mishka.ui.gen.component textarea_field
     mix mishka.ui.gen.component native_select
     mix mishka.ui.gen.component checkbox_field
     mix mishka.ui.gen.component number_field
     mix mishka.ui.gen.component combobox
     # ... etc
     ```

  **Characteristics:**
  - Full component library
  - DaisyUI/Tailwind styling
  - Searchable combobox support
  - More customization options

  ### Option 3: Custom Theme

  Implement your own theme by following the [Customization Guide](AshFormBuilder.Guide.Customization.html).

  ---

  ## Setup Ash Resources

  ### Step 1: Add Extension

  In your Ash Resource, add the `AshFormBuilder` extension:

  ```elixir
  defmodule MyApp.Todos.Task do
    use Ash.Resource,
      domain: MyApp.Todos,
      data_layer: AshPostgres.DataLayer,
      extensions: [AshFormBuilder]  # ← Add this

    # ... rest of resource definition
  end
  ```

  ### Step 2: Define Form DSL

  Add a `form` block to your resource:

  ```elixir
  form do
    action :create
    # Fields are auto-inferred from action.accept
  end
  ```

  ### Step 3: Configure Domain

  Add form code interfaces to your Domain:

  ```elixir
  defmodule MyApp.Todos do
    use Ash.Domain

    resources do
      resource MyApp.Todos.Task do
        # Generates MyApp.Todos.Task.Form.for_create/1
        define :form_to_create_task, action: :create
        define :form_to_update_task, action: :update
      end
    end
  end
  ```

  ---

  ## Verify Installation

  ### Quick Test

  Create a simple test resource:

  ```elixir
  defmodule MyApp.Test.Resource do
    use Ash.Resource,
      domain: MyApp.Test,
      extensions: [AshFormBuilder]

    attributes do
      uuid_primary_key :id
      attribute :name, :string, allow_nil?: false
    end

    actions do
      create :create do
        accept [:name]
      end
    end

    form do
      action :create
    end
  end
  ```

  Check that the form module is generated:

  ```bash
  iex -S mix

  iex> MyApp.Test.Resource.Form.for_create()
  %Phoenix.HTML.Form{...}
  ```

  ### Check Theme Configuration

  ```elixir
  iex> Application.get_env(:ash_form_builder, :theme)
  AshFormBuilder.Themes.Default  # or your configured theme
  ```

  ---

  ## Troubleshooting

  ### Issue: "module AshFormBuilder is not available"

  **Solution:** Ensure the extension is added to your resource:

  ```elixir
  extensions: [AshFormBuilder]
  ```

  ### Issue: "form/1 macro is undefined"

  **Solution:** Make sure you're inside an `Ash.Resource` definition with the extension added.

  ### Issue: "theme module not found"

  **Solution:** Check your config:

  ```elixir
  # config/config.exs
  config :ash_form_builder, :theme, AshFormBuilder.Themes.Default
  ```

  Then restart your application:

  ```bash
  mix compile
  ```

  ### Issue: "function Form.for_create/1 is undefined"

  **Solution:** Ensure you've defined the code interface in your Domain:

  ```elixir
  define :form_to_create_task, action: :create
  ```

  ### Issue: Compilation errors with MishkaTheme

  **Solution:** Generate the required Mishka components:

  ```bash
  mix mishka.ui.gen.component text_field
  mix mishka.ui.gen.component combobox
  # ... etc
  ```

  Or switch to the Default theme temporarily:

  ```elixir
  config :ash_form_builder, :theme, AshFormBuilder.Themes.Default
  ```

  ---

  ## Next Steps

  After successful installation:

  1. ✅ Read the [Quick Start Guide](AshFormBuilder.html#module-quick-start)
  2. ✅ Explore the [Todo App Tutorial](AshFormBuilder.Guide.TodoApp.html)
  3. ✅ Learn about [Field Types](AshFormBuilder.Guide.Fields.html)
  4. ✅ Study [Relationship Handling](AshFormBuilder.Guide.Relationships.html)

  ---

  ## Getting Help

  - 📚 [Documentation](https://hexdocs.pm/ash_form_builder)
  - 💬 [Ash Framework Discord](https://discord.gg/ash-framework)
  - 🐛 [Report Issues](https://github.com/nagieeb0/ash_form_builder/issues)
  - 💡 [GitHub Discussions](https://github.com/nagieeb0/ash_form_builder/discussions)
  """
end
