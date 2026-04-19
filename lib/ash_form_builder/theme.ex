defmodule AshFormBuilder.Theme do
  @moduledoc """
  Behaviour for comprehensive theme customization in AshFormBuilder v0.2.0.

  A theme module renders individual form fields by implementing `c:render_field/2`.
  The structural rendering (entity iteration, nested-form `inputs_for` loops,
  add/remove buttons) is handled by `AshFormBuilder.FormRenderer`, but themes
  can customize nested form rendering via `c:render_nested/1`.

  ## Configuring a Theme

      # config/config.exs
      config :ash_form_builder, :theme, MyAppWeb.CustomTheme

      # With global options
      config :ash_form_builder,
        theme: AshFormBuilder.Theme.MishkaTheme,
        theme_opts: [
          wrapper_class: "space-y-6",
          field_wrapper_class: "mb-4",
          label_class: "block text-sm font-medium mb-1",
          input_class: "w-full px-3 py-2 border rounded-md",
          error_class: "text-sm text-red-600 mt-1",
          hint_class: "text-sm text-gray-500 mt-1"
        ]

  ## Implementing a Custom Theme

      defmodule MyAppWeb.CustomTheme do
        @behaviour AshFormBuilder.Theme
        use Phoenix.Component

        @impl AshFormBuilder.Theme
        def render_field(assigns, opts) do
          case assigns.field.type do
            :text_input -> render_text_input(assigns)
            :textarea -> render_textarea(assigns)
            :multiselect_combobox -> render_combobox(assigns)
            _ -> render_default(assigns)
          end
        end

        @impl AshFormBuilder.Theme
        def render_nested(assigns) do
          # Optional: customize nested form rendering
          nil  # Falls back to default
        end

        defp render_text_input(assigns) do
          ~H\"""
          <div class={[@theme_opts[:field_wrapper_class], "form-group"]}>
            <label for={Phoenix.HTML.Form.input_id(@form, @field.name)}>
              {@field.label}
            </label>
            <input
              type="text"
              id={Phoenix.HTML.Form.input_id(@form, @field.name)}
              class="form-control"
            />
          </div>
          \"""
        end
      end

  ## Theme Callbacks

  ### Required

  * `c:render_field/2` - Renders individual form fields

  ### Optional

  * `c:render_nested/1` - Customizes nested form rendering
  * `c:render_component/2` - Renders specific component types (for advanced customization)

  ## Assigns Guaranteed in `render_field/2`

  | Key | Type | Description |
  |-----|------|-------------|
  | `:form` | `Phoenix.HTML.Form` | The parent or nested form |
  | `:field` | `AshFormBuilder.Field` | The field struct to render |
  | `:theme_opts` | `keyword()` | Theme-specific options from config |

  ## Field Types

  Themes must handle these field types:

  * `:text_input` - Standard text input
  * `:textarea` - Multi-line text area
  * `:select` - Single-select dropdown
  * `:multiselect_combobox` - Many-to-many searchable multi-select
  * `:checkbox` - Boolean checkbox
  * `:number` - Numeric input
  * `:email` - Email input
  * `:password` - Password input
  * `:date` - Date picker
  * `:datetime` - DateTime picker
  * `:hidden` - Hidden input
  * `:url` - URL input
  * `:tel` - Telephone input

  ## Special Handling for `:multiselect_combobox`

  When a field has `type: :multiselect_combobox`, it represents a many_to_many
  relationship. The field's `:opts` key contains:

  * `:search_event` - Event name for searching
  * `:search_param` - Query param name (default: "query")
  * `:debounce` - Search debounce in ms (default: 300)
  * `:creatable` - Allow creating new items (default: false)
  * `:create_action` - Action for creating items (default: :create)
  * `:label_key` - Field for labels (default: `:name`)
  * `:value_key` - Field for values (default: `:id`)
  """

  @doc """
  Renders a complete field: label, input widget, hint text, and validation errors.

  ## Assigns

  * `:form` - `Phoenix.HTML.Form` - The parent or nested form
  * `:field` - `AshFormBuilder.Field` - The field struct to render
  * `:theme_opts` - Theme-specific options passed from renderer

  ## Opts

  Additional options passed from the renderer (e.g., custom styling, event handlers).
  """
  @callback render_field(assigns :: map(), opts :: keyword()) :: Phoenix.LiveView.Rendered.t()

  @doc """
  Renders a nested form block. Optional - if not implemented, the default
  rendering in `FormRenderer` will be used.

  ## Assigns

  * `:form` - `Phoenix.HTML.Form` - The parent form
  * `:nested` - `AshFormBuilder.NestedForm` - The nested form configuration
  * `:target` - LiveComponent target (`@myself`)
  * `:theme` - The theme module (for recursive field rendering)

  Return `nil` to fall back to the default nested form rendering.
  """
  @callback render_nested(assigns :: map()) :: Phoenix.LiveView.Rendered.t() | nil

  @doc """
  Renders a specific component type. Optional - for advanced theme customization.

  Allows themes to inject custom components for specific field types or UI patterns.

  ## Examples

      def render_component(:combobox, assigns) do
        # Custom combobox implementation
      end

      def render_component(_, _), do: nil  # Fallback to default
  """
  @callback render_component(atom(), assigns :: map()) :: Phoenix.LiveView.Rendered.t() | nil

  @optional_callbacks render_nested: 1, render_component: 2
end
