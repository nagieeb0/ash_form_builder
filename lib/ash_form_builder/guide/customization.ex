defmodule AshFormBuilder.Guide.Customization do
  @moduledoc """
  # Customization Guide

  Learn how to customize AshFormBuilder themes, fields, and rendering.

  ## Contents

  1. [Theme System Overview](#module-theme-system-overview)
  2. [Creating Custom Themes](#module-creating-custom-themes)
  3. [Field Customization](#module-field-customization)
  4. [Combobox Customization](#module-combobox-customization)
  5. [Nested Form Customization](#module-nested-form-customization)
  6. [CSS & Styling](#module-css-and-styling)
  7. [Advanced Customization](#module-advanced-customization)

  ---

  ## Theme System Overview

  AshFormBuilder uses a theme system to separate form logic from UI rendering.

  ### Built-in Themes

  | Theme | Description | Best For |
  |-------|-------------|----------|
  | `AshFormBuilder.Themes.Default` | Semantic HTML, minimal styling | Quick setup, custom styling |
  | `AshFormBuilder.Theme.MishkaTheme` | MishkaChelekom components | DaisyUI/Tailwind projects |

  ### Configure Theme

  ```elixir
  # config/config.exs
  config :ash_form_builder, :theme, AshFormBuilder.Themes.Default
  ```

  ### Theme Behaviour

  Themes implement the `AshFormBuilder.Theme` behaviour:

  ```elixir
  defmodule CustomTheme do
    @behaviour AshFormBuilder.Theme
    use Phoenix.Component

    @impl AshFormBuilder.Theme
    def render_field(assigns, opts) do
      # Render field based on assigns.field.type
    end

    @impl AshFormBuilder.Theme
    def render_nested(assigns) do
      # Optional: customize nested form rendering
    end
  end
  ```

  ---

  ## Creating Custom Themes

  ### Step 1: Create Theme Module

  ```elixir
  defmodule MyAppWeb.CustomTheme do
    @behaviour AshFormBuilder.Theme
    use Phoenix.Component

    @impl AshFormBuilder.Theme
    def render_field(assigns, opts) do
      assigns = Map.put(assigns, :theme_opts, opts)

      case assigns.field.type do
        :text_input -> render_text_input(assigns)
        :textarea -> render_textarea(assigns)
        :select -> render_select(assigns)
        :multiselect_combobox -> render_combobox(assigns)
        :checkbox -> render_checkbox(assigns)
        :number -> render_number(assigns)
        :email -> render_email(assigns)
        :password -> render_password(assigns)
        :date -> render_date(assigns)
        :datetime -> render_datetime(assigns)
        :url -> render_url(assigns)
        :tel -> render_tel(assigns)
        :hidden -> render_hidden(assigns)
        _ -> render_text_input(assigns)
      end
    end

    @impl AshFormBuilder.Theme
    def render_nested(_assigns) do
      nil  # Use default nested rendering
    end
  end
  ```

  ### Step 2: Implement Field Renderers

  Example: Text Input

  ```elixir
  defp render_text_input(assigns) do
    ~H"""
    <div class={["mb-4", @field.wrapper_class]}>
      <label
        :if={@field.label}
        for={Phoenix.HTML.Form.input_id(@form, @field.name)}
        class="block text-sm font-medium text-gray-700 mb-1"
      >
        {@field.label}
        <span :if={@field.required} class="text-red-500 ml-1">*</span>
      </label>

      <input
        type="text"
        id={Phoenix.HTML.Form.input_id(@form, @field.name)}
        name={Phoenix.HTML.Form.input_name(@form, @field.name)}
        value={Phoenix.HTML.Form.input_value(@form, @field.name)}
        placeholder={@field.placeholder}
        class="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
      />

      <p :if={@field.hint} class="mt-1 text-sm text-gray-500">{@field.hint}</p>

      <.errors :for={err <- (@form[@field.name] || %{errors: []}).errors} message={elem(err, 0)} />
    </div>
    """
  end
  ```

  ### Step 3: Error Component

  ```elixir
  attr(:message, :string, required: true)

  defp errors(assigns) do
    ~H"""
    <p class="mt-1 text-sm text-red-600">{@message}</p>
    """
  end
  ```

  ### Step 4: Configure Theme

  ```elixir
  # config/config.exs
  config :ash_form_builder, :theme, MyAppWeb.CustomTheme
  ```

  ---

  ## Field Customization

  ### Override Auto-Inferred Fields

  ```elixir
  form do
    action :create

    field :title do
      label "Task Title"
      type :text_input
      placeholder "What needs to be done?"
      required true
      hint "Keep it concise but descriptive"
      class "input-lg font-bold"
      wrapper_class "mb-6"
    end
  end
  ```

  ### Field Options

  | Option | Type | Description |
  |--------|------|-------------|
  | `:label` | String | Field label |
  | `:type` | Atom | UI type (overrides auto-inference) |
  | `:placeholder` | String | Placeholder text |
  | `:required` | Boolean | Show required indicator |
  | `:options` | List | Options for `:select` fields |
  | `:class` | String | CSS class on input element |
  | `:wrapper_class` | String | CSS class on wrapper div |
  | `:hint` | String | Helper text below field |
  | `:opts` | Keyword | Custom options (for combobox, etc.) |

  ### Custom Field Types

  Create custom field types by extending the theme:

  ```elixir
  # In your theme module
  defp render_custom_field(assigns) do
    ~H"""
    <div class="custom-field">
      <input
        type="text"
        data-custom="true"
        class="custom-input"
      />
    </div>
    """
  end
  ```

  ---

  ## Combobox Customization

  ### Basic Combobox

  ```elixir
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
  ```

  ### Creatable Combobox

  ```elixir
  field :tags do
    type :multiselect_combobox
    label "Tags"

    opts [
      creatable: true,
      create_action: :create,
      create_label: "Create \"",
      search_event: "search_tags",
      debounce: 300,
      label_key: :name,
      value_key: :id,
      hint: "Search or create new tags"
    ]
  end
  ```

  ### Preload Options

  For small datasets (< 100 items):

  ```elixir
  field :categories do
    type :multiselect_combobox

    opts [
      preload_options: [
        {"Engineering", "eng-uuid"},
        {"Marketing", "mkt-uuid"},
        {"Sales", "sales-uuid"}
      ]
    ]
  end
  ```

  ### Custom Search Parameters

  ```elixir
  field :users do
    type :multiselect_combobox

    opts [
      search_event: "search_users",
      search_param: "query",  # Default: "query"
      debounce: 500,          # Default: 300ms
      label_key: :full_name,  # Custom field for label
      value_key: :uuid        # Custom field for value
    ]
  end
  ```

  ---

  ## Nested Form Customization

  ### Basic Nested Form

  ```elixir
  nested :subtasks do
    label "Subtasks"
    cardinality :many
    add_label "Add Subtask"
    remove_label "Remove"
    class "nested-subtasks border rounded p-4"

    field :title do
      label "Subtask"
      required true
    end
  end
  ```

  ### Nested Form Options

  | Option | Type | Description |
  |--------|------|-------------|
  | `:label` | String | Fieldset legend |
  | `:cardinality` | Atom | `:many` or `:one` |
  | `:add_label` | String | Add button text |
  | `:remove_label` | String | Remove button text |
  | `:class` | String | Fieldset CSS class |
  | `:create_action` | Atom | Nested create action |
  | `:update_action` | Atom | Nested update action |

  ### Custom Nested Rendering

  In your theme:

  ```elixir
  @impl AshFormBuilder.Theme
  def render_nested(assigns) do
    ~H"""
    <fieldset class={@nested.class}>
      <legend><%= @nested.label %></legend>

      <.inputs_for :let={nested_form} field={@form[@nested.name]}>
        <div class="nested-item">
          <%= for field <- @nested.fields do %>
            <%= @theme.render_field(%{form: nested_form, field: field}, []) %>
          <% end %>

          <button
            type="button"
            phx-click="remove_form"
            phx-value-path={nested_form.name}
          >
            {@nested.remove_label}
          </button>
        </div>
      </.inputs_for>

      <button
        type="button"
        phx-click="add_form"
        phx-value-path={to_string(@nested.name)}
      >
        {@nested.add_label}
      </button>
    </fieldset>
    """
  end
  ```

  ---

  ## CSS and Styling

  ### Default Theme Classes

  The default theme uses semantic classes:

  ```html
  <div class="mb-4">
    <label class="block text-sm font-medium mb-1">
      Field Label
      <span class="text-error ml-1">*</span>
    </label>
    <input class="input input-bordered w-full" />
    <p class="text-xs text-base-content/60 mt-1">Hint text</p>
    <p class="text-xs text-error mt-1">Error message</p>
  </div>
  ```

  ### Tailwind CSS Integration

  ```elixir
  defp render_text_input(assigns) do
    ~H"""
    <div class={["mb-4", @field.wrapper_class]}>
      <label
        for={Phoenix.HTML.Form.input_id(@form, @field.name)}
        class="block text-sm font-medium text-gray-700 mb-1"
      >
        {@field.label}
      </label>

      <input
        type="text"
        id={Phoenix.HTML.Form.input_id(@form, @field.name)}
        class="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
      />
    </div>
    """
  end
  ```

  ### DaisyUI Integration

  ```elixir
  defp render_text_input(assigns) do
    ~H"""
    <div class="form-control w-full mb-4">
      <label class="label">
        <span class="label-text">{@field.label}</span>
        <span :if={@field.required} class="label-text-alt text-error">*</span>
      </label>

      <input
        type="text"
        id={Phoenix.HTML.Form.input_id(@form, @field.name)}
        class="input input-bordered w-full"
        placeholder={@field.placeholder}
      />

      <label :if={@field.hint} class="label">
        <span class="label-text-alt">{@field.hint}</span>
      </label>
    </div>
    """
  end
  ```

  ---

  ## Advanced Customization

  ### Dynamic Field Options

  Load options dynamically in LiveView:

  ```elixir
  def mount(_params, _session, socket) do
    form = Task.Form.for_create(actor: socket.assigns.current_user)

    {:ok,
     socket
     |> assign(:form, form)
     |> assign(:priority_options, load_priority_options())}
  end

  defp load_priority_options do
    [
      {"🔵 Low", :low},
      {"🟡 Medium", :medium},
      {"🔴 High", :high},
      {"⚠️ Urgent", :urgent}
    ]
  end
  ```

  ### Conditional Fields

  Show/hide fields based on other values:

  ```elixir
  # In LiveView template
  def render(assigns) do
    ~H"""
    <.form for={@form}>
      <.input field={@form[:project_type]} type="select" options={["Simple", "Complex"]} />

      <%= if @form.source.data.project_type == :complex do %>
        <.nested_form :for={phase <- @form[:phases]} ... />
      <% end %>
    </.form>
    """
  end
  ```

  ### Custom Validation Styling

  ```elixir
  defp render_text_input(assigns) do
    has_error = !is_nil(@form[@field.name]) && length(@form[@field.name].errors) > 0

    ~H"""
    <div class={["mb-4", if(has_error, do: "has-error")]}>
      <input
        class={
          if has_error do
            "input input-bordered input-error w-full"
          else
            "input input-bordered w-full"
          end
        }
      />
      <.errors :for={err <- @form[@field.name].errors} message={elem(err, 0)} />
    </div>
    """
  end
  ```

  ### Theme Composition

  Create theme adapters that compose multiple themes:

  ```elixir
  defmodule MyAppWeb.ComposedTheme do
    @behaviour AshFormBuilder.Theme

    def render_field(assigns, opts) do
      # Use Default theme for most fields
      case assigns.field.type do
        :multiselect_combobox -> MyAppWeb.ComboboxTheme.render_field(assigns, opts)
        _ -> AshFormBuilder.Themes.Default.render_field(assigns, opts)
      end
    end
  end
  ```

  ---

  ## Examples

  ### Complete Custom Theme Example

  See `example_usage.ex` in the package for a complete custom theme implementation.

  ### Real-World Examples

  - [Todo App Theme](AshFormBuilder.Guide.TodoApp.html) - Complete working example
  - [MishkaTheme Source](https://github.com/nagieeb0/ash_form_builder/blob/main/lib/ash_form_builder/theme/mishka_theme.ex) - Production theme

  ---

  ## Getting Help

  - 📚 [Installation Guide](AshFormBuilder.Guide.Installation.html)
  - 💬 [Ash Framework Discord](https://discord.gg/ash-framework)
  - 🐛 [Report Issues](https://github.com/nagieeb0/ash_form_builder/issues)
  """
end
