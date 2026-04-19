defmodule AshFormBuilder.Theme do
  @moduledoc """
  Behaviour for AshFormBuilder rendering themes.

  A theme module renders individual form fields by implementing `render_field/1`.
  The structural rendering (entity iteration, nested-form `inputs_for` loops,
  add/remove buttons) is handled by `AshFormBuilder.FormRenderer` and is not
  part of this behaviour — only the per-field widget + wrapper is themed.

  ## Configuring a theme

      # config/config.exs
      config :ash_form_builder, :theme, MyAppWeb.MishkaFormTheme

  The default theme is `AshFormBuilder.Themes.Default`.

  ## Implementing a theme

      defmodule MyApp.CustomTheme do
        @behaviour AshFormBuilder.Theme
        use Phoenix.Component

        @impl AshFormBuilder.Theme
        def render_field(%{field: %AshFormBuilder.Field{type: :hidden}} = assigns) do
          ~H\"""
          <input type="hidden"
            id={Phoenix.HTML.Form.input_id(@form, @field.name)}
            name={Phoenix.HTML.Form.input_name(@form, @field.name)}
            value={Phoenix.HTML.Form.input_value(@form, @field.name)} />
          \"""
        end

        def render_field(assigns) do
          ~H\"""
          <div class="my-field-wrapper">
            <label for={Phoenix.HTML.Form.input_id(@form, @field.name)}>
              {@field.label}
            </label>
            <!-- render input based on @field.type ... -->
          </div>
          \"""
        end
      end

  ## Assigns guaranteed in `render_field/1`

  | key     | type                 | description                    |
  |---------|----------------------|--------------------------------|
  | `:form` | `Phoenix.HTML.Form`  | The parent or nested form      |
  | `:field`| `AshFormBuilder.Field` | The field struct to render   |
  """

  @doc """
  Renders a complete field: label, input widget, hint text, and validation errors.

  Guaranteed assigns: `:form` (`Phoenix.HTML.Form`) and `:field` (`AshFormBuilder.Field`).
  """
  @callback render_field(assigns :: map()) :: Phoenix.LiveView.Rendered.t()
end
