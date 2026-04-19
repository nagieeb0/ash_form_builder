defmodule AshFormBuilder.Theme do
  @moduledoc """
  Behaviour for AshFormBuilder rendering themes.

  A theme module renders individual form fields by implementing `c:render_field/2`.
  The structural rendering (entity iteration, nested-form `inputs_for` loops,
  add/remove buttons) is handled by `AshFormBuilder.FormRenderer`, but themes
  can customize nested form rendering via `c:render_nested/1`.

  ## Configuring a theme

      # config/config.exs
      config :ash_form_builder, :theme, MyAppWeb.MishkaFormTheme

  The default theme is `AshFormBuilder.Themes.Default`.

  ## Implementing a theme

      defmodule MyApp.CustomTheme do
        @behaviour AshFormBuilder.Theme
        use Phoenix.Component

        @impl AshFormBuilder.Theme
        def render_field(assigns, _opts) do
          # Render a single field
        end

        @impl AshFormBuilder.Theme
        def render_nested(assigns) do
          # Optionally customize nested form rendering
        end
      end

  ## Assigns guaranteed in `render_field/2`

  | key     | type                 | description                    |
  |---------|----------------------|--------------------------------|
  | `:form` | `Phoenix.HTML.Form`  | The parent or nested form      |
  | `:field`| `AshFormBuilder.Field` | The field struct to render   |

  ## Field Types

  Themes must handle these field types:

  * `:text_input` - Standard text input
  * `:textarea` - Multi-line text area
  * `:select` - Single-select dropdown
  * `:multiselect_combobox` - Many-to-many searchable multi-select (MishkaChelekom combobox)
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
  * `:preload_options` - Preloaded options as `[{label, value}]`
  * `:label_key` - Field for labels (default: `:name`)
  * `:value_key` - Field for values (default: `:id`)
  """

  @doc """
  Renders a complete field: label, input widget, hint text, and validation errors.

  ## Assigns

  * `:form` - `Phoenix.HTML.Form` - The parent or nested form
  * `:field` - `AshFormBuilder.Field` - The field struct to render

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

  @optional_callbacks render_nested: 1
end
