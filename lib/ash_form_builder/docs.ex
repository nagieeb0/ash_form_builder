defmodule AshFormBuilder do
  @moduledoc """
  # AshFormBuilder - Declarative Forms for Ash Framework

  > ⚠️ **EXPERIMENTAL - Use at Your Own Risk**
  >
  > This package is under active development. API may change without notice.
  > Not recommended for critical production systems without thorough testing.

  A declarative form generation engine for [Ash Framework](https://ash-hq.org/) and [Phoenix LiveView](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html).

  ## 📚 Table of Contents

  1. [Installation](#module-installation)
  2. [Quick Start](#module-quick-start)
  3. [Core Concepts](#module-core-concepts)
  4. [Guides](#module-guides)
  5. [Customization](#module-customization)
  6. [API Reference](#module-api-reference)

  ---

  ## Installation

  ### Step 1: Add Dependency

  Add `ash_form_builder` to your `mix.exs` dependencies:

  ```elixir
  defp deps do
    [
      {:ash, "~> 3.0"},
      {:ash_phoenix, "~> 2.0"},
      {:ash_form_builder, "~> 0.1.0"}  # ⚠️ EXPERIMENTAL
    ]
  end
  ```

  Then run:

  ```bash
  mix deps.get
  ```

  ### Step 2: Configure Theme

  Choose a theme in your `config/config.exs`:

  ```elixir
  # Default HTML theme (semantic HTML, no dependencies)
  config :ash_form_builder, :theme, AshFormBuilder.Themes.Default

  # MishkaChelekom theme (requires mishka_chelekom dependency)
  config :ash_form_builder, :theme, AshFormBuilder.Theme.MishkaTheme

  # Custom theme (implement AshFormBuilder.Theme behaviour)
  config :ash_form_builder, :theme, MyAppWeb.CustomTheme
  ```

  ### Step 3: Add Extension to Resource

  In your Ash Resource, add the extension:

  ```elixir
  defmodule MyApp.Todos.Task do
    use Ash.Resource,
      domain: MyApp.Todos,
      extensions: [AshFormBuilder]  # ← Add this

    # ... rest of your resource
  end
  ```

  ---

  ## Quick Start

  ### Minimal Setup (Auto-Inference)

  The simplest approach - fields are auto-inferred from your action's `accept` list:

  ```elixir
  defmodule MyApp.Todos.Task do
    use Ash.Resource,
      domain: MyApp.Todos,
      extensions: [AshFormBuilder]

    attributes do
      uuid_primary_key :id
      attribute :title, :string, allow_nil?: false
      attribute :description, :text
      attribute :completed, :boolean, default: false
    end

    actions do
      create :create do
        accept [:title, :description, :completed]
      end
    end

    form do
      action :create  # That's it! Fields are auto-inferred.
    end
  end
  ```

  ### Domain Configuration

  Define form code interfaces in your Domain:

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

  ### LiveView Integration

  ```elixir
  defmodule MyAppWeb.TaskLive.Form do
    use MyAppWeb, :live_view

    def mount(_params, _session, socket) do
      form = MyApp.Todos.Task.Form.for_create(actor: socket.assigns.current_user)
      {:ok, assign(socket, form: form)}
    end

    def render(assigns) do
      ~H"""
      <.live_component
        module={AshFormBuilder.FormComponent}
        id="task-form"
        resource={MyApp.Todos.Task}
        form={@form}
      />
      """
    end

    def handle_info({:form_submitted, MyApp.Todos.Task, task}, socket) do
      {:noreply, push_navigate(socket, to: ~p"/tasks/#{task.id}")}
    end
  end
  ```

  ---

  ## Core Concepts

  ### Auto-Inference Engine

  Fields are automatically mapped from Ash types to UI components:

  | Ash Type | UI Type | Example |
  |----------|---------|---------|
  | `:string` | `:text_input` | Text fields |
  | `:text` | `:textarea` | Multi-line text |
  | `:boolean` | `:checkbox` | Toggle switches |
  | `:integer` | `:number` | Numeric inputs |
  | `:date` | `:date` | Date pickers |
  | `:datetime` | `:datetime` | DateTime pickers |
  | `:atom` + `one_of:` | `:select` | Dropdowns |
  | `many_to_many` | `:multiselect_combobox` | Searchable multi-select |

  ### Field Types

  #### Standard Fields

  ```elixir
  form do
    field :title do
      label "Task Title"
      type :text_input
      placeholder "Enter title"
      required true
      hint "Keep it concise"
    end

    field :description do
      label "Description"
      type :textarea
      rows 4
    end

    field :priority do
      label "Priority"
      type :select
      options: [
        {"Low", :low},
        {"Medium", :medium},
        {"High", :high}
      ]
    end
  end
  ```

  #### Many-to-Many Combobox

  ```elixir
  form do
    field :tags do
      type :multiselect_combobox
      label "Tags"
      placeholder "Search tags..."

      opts [
        search_event: "search_tags",
        debounce: 300,
        label_key: :name,
        value_key: :id
      ]
    end
  end
  ```

  #### Creatable Combobox ⭐ NEW

  Allow users to create new items on-the-fly:

  ```elixir
  form do
    field :tags do
      type :multiselect_combobox
      label "Tags"

      opts [
        creatable: true,              # ← Enable creating
        create_action: :create,
        create_label: "Create \"",
        search_event: "search_tags"
      ]
    end
  end
  ```

  #### Nested Forms (has_many)

  Dynamic add/remove for child records:

  ```elixir
  form do
    nested :subtasks do
      label "Subtasks"
      cardinality :many
      add_label "Add Subtask"

      field :title do
        label "Subtask"
        required true
      end
    end
  end
  ```

  ---

  ## Guides

  ### 📖 Available Guides

  Comprehensive guides are included in the package:

  1. **[Todo App Integration](TodoAppGuide.html)** - Complete step-by-step tutorial building a Todo app
  2. **[Relationships Guide](RelationshipsGuide.html)** - has_many vs many_to_many, filtering, limits
  3. **[Example Usage](example_usage.ex.html)** - Reference documentation with all features

  ### Guide Topics

  - Installation and setup
  - Resource definition
  - Domain configuration
  - LiveView integration
  - Search handlers
  - Creatable combobox
  - Nested forms
  - Theme customization
  - Testing strategies

  ---

  ## Customization

  ### Theme System

  Create custom themes by implementing the `AshFormBuilder.Theme` behaviour:

  ```elixir
  defmodule MyAppWeb.CustomTheme do
    @behaviour AshFormBuilder.Theme
    use Phoenix.Component

    @impl AshFormBuilder.Theme
    def render_field(assigns, opts) do
      case assigns.field.type do
        :text_input -> render_text_input(assigns)
        :textarea -> render_textarea(assigns)
        :multiselect_combobox -> render_combobox(assigns)
        # ... etc
      end
    end

    defp render_text_input(assigns) do
      ~H"""
      <div class="form-group">
        <label for={Phoenix.HTML.Form.input_id(@form, @field.name)}>
          {@field.label}
        </label>
        <input
          type="text"
          id={Phoenix.HTML.Form.input_id(@form, @field.name)}
          name={Phoenix.HTML.Form.input_name(@form, @field.name)}
          value={Phoenix.HTML.Form.input_value(@form, @field.name)}
          class="form-control"
        />
      </div>
      """
    end
  end
  ```

  ### Field Customization

  Override auto-inferred fields:

  ```elixir
  form do
    action :create

    field :title do
      label "Task Title"
      placeholder "What needs to be done?"
      required true
      class "input-lg"
      wrapper_class "mb-4"
    end

    field :priority do
      label "Priority Level"
      type :select
      options: [
        {"🔵 Low", :low},
        {"🟡 Medium", :medium},
        {"🔴 High", :high}
      ]
      default :medium
    end
  end
  ```

  ### Combobox Options

  Customize combobox behavior:

  ```elixir
  field :assignees do
    type :multiselect_combobox

    opts [
      # Search configuration
      search_event: "search_users",
      debounce: 300,
      search_param: "query",

      # Field mappings
      label_key: :name,
      value_key: :id,

      # Preload options (small datasets)
      preload_options: fn -> load_users() end,

      # Creatable options
      creatable: true,
      create_action: :create,
      create_label: "Create \"",

      # Custom hints
      hint: "Search users or create new ones"
    ]
  end
  ```

  ---

  ## API Reference

  ### Modules

  - `AshFormBuilder` - Main module (you are here)
  - `AshFormBuilder.FormComponent` - LiveComponent for rendering forms
  - `AshFormBuilder.FormRenderer` - Renders form entities
  - `AshFormBuilder.Infer` - Auto-inference engine
  - `AshFormBuilder.Info` - DSL introspection utilities
  - `AshFormBuilder.Field` - Field struct definition
  - `AshFormBuilder.NestedForm` - Nested form struct
  - `AshFormBuilder.Theme` - Theme behaviour
  - `AshFormBuilder.Theme.MishkaTheme` - MishkaChelekom adapter
  - `AshFormBuilder.Themes.Default` - Default theme

  ### DSL Sections

  - `form/1` - Main form configuration
  - `field/2` - Field declaration
  - `nested/2` - Nested form declaration

  ---

  ## ⚠️ Experimental Status

  **This package is EXPERIMENTAL and under active development.**

  ### What This Means

  - ✅ Core functionality is working and tested
  - ⚠️ API may change without notice
  - ⚠️ Breaking changes likely in minor versions (0.x.y)
  - ⚠️ Not all edge cases are handled
  - ⚠️ Documentation may be incomplete

  ### For Production Use

  If you choose to use this in production:

  1. **Pin to exact version**: `{:ash_form_builder, "== 0.1.0"}`
  2. **Test thoroughly** before deployment
  3. **Monitor the repository** for updates
  4. **Be prepared** to handle breaking changes
  5. **Consider contributing** fixes and improvements

  ---

  ## 🔗 Links

  - [GitHub Repository](https://github.com/nagieeb0/ash_form_builder)
  - [Ash Framework Documentation](https://hexdocs.pm/ash)
  - [Phoenix LiveView Documentation](https://hexdocs.pm/phoenix_live_view)
  - [Report Issues](https://github.com/nagieeb0/ash_form_builder/issues)

  ---

  ## 📄 License

  MIT License - see [LICENSE](https://github.com/nagieeb0/ash_form_builder/blob/main/LICENSE) for details.
  """

  use Spark.Dsl.Extension,
    sections: AshFormBuilder.Dsl.sections(),
    transformers: AshFormBuilder.Dsl.transformers()
end
