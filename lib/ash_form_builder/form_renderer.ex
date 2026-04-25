defmodule AshFormBuilder.FormRenderer do
  @moduledoc """
  Phoenix function components that render form entities.

  Structural rendering (entity iteration, nested `inputs_for` loops, add/remove
  buttons) lives here. Per-field widget rendering is delegated to the configured
  theme module via `AshFormBuilder.Theme`.

  ## Theme configuration

      config :ash_form_builder, :theme, MyApp.MyFormTheme

  Default: `AshFormBuilder.Themes.Default`.

  ## Theme Callbacks

  The theme module implements:

  * `c:AshFormBuilder.Theme.render_field/2` - Renders individual form fields
  * `c:AshFormBuilder.Theme.render_nested/1` - (Optional) Custom nested form rendering
  """

  use Phoenix.Component

  # ---------------------------------------------------------------------------
  # Public API
  # ---------------------------------------------------------------------------

  @doc """
  Renders all entities (fields and nested forms) for a form.

  Required assigns:
    * `:form`          — `Phoenix.HTML.Form`
    * `:entities`      — list of `Field` and `NestedForm` structs
    * `:target`        — LiveComponent target (`@myself`)
    * `:wrapper_class` — CSS class for the wrapper div
  """
  attr(:form, Phoenix.HTML.Form, required: true)
  attr(:entities, :list, required: true)
  attr(:target, :any, default: nil)
  attr(:wrapper_class, :string, default: "space-y-4")
  attr(:theme_opts, :list, default: [])
  attr(:uploads, :map, default: %{})

  def form_fields(assigns) do
    assigns = assign(assigns, :theme, theme_module())

    ~H"""
    <div class={@wrapper_class}>
      <%= for entity <- @entities do %>
        <%= if is_struct(entity, AshFormBuilder.Field) do %>
          <%= @theme.render_field(
            %{form: @form, field: entity, target: @target, uploads: @uploads},
            @theme_opts
          ) %>
        <% end %>
        <%= if is_struct(entity, AshFormBuilder.NestedForm) do %>
          <.nested_form form={@form} nested={entity} target={@target} theme_opts={@theme_opts} />
        <% end %>
      <% end %>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Nested form — structural rendering stays here
  # ---------------------------------------------------------------------------

  @doc "Renders a nested relationship form block with add/remove buttons."
  attr(:form, Phoenix.HTML.Form, required: true)
  attr(:nested, :any, required: true)
  attr(:target, :any, default: nil)
  attr(:theme_opts, :list, default: [])

  def nested_form(assigns) do
    theme = theme_module()
    assigns = assign(assigns, :theme, theme)

    # Allow theme to override nested form rendering
    if function_exported?(theme, :render_nested, 1) do
      case theme.render_nested(assigns) do
        nil -> render_default_nested_form(assigns)
        rendered -> rendered
      end
    else
      render_default_nested_form(assigns)
    end
  end

  # ---------------------------------------------------------------------------
  # Default nested form rendering
  # ---------------------------------------------------------------------------

  defp render_default_nested_form(assigns) do
    ~H"""
    <fieldset class={["nested-form", @nested.class]}>
      <legend :if={@nested.label} class="nested-legend">{@nested.label}</legend>

      <.inputs_for :let={nested_f} field={@form[@nested.name]}>
        <div class="nested-item">
          <%= for f <- @nested.fields do %>
            <%= @theme.render_field(
              %{form: nested_f, field: f, target: @target, uploads: %{}},
              @theme_opts
            ) %>
          <% end %>

          <button
            :if={@nested.cardinality == :many}
            type="button"
            phx-click="remove_form"
            phx-value-path={nested_f.name}
            phx-target={@target}
            class="btn-remove-nested"
          >
            {@nested.remove_label}
          </button>
        </div>
      </.inputs_for>

      <button
        :if={@nested.cardinality == :many}
        type="button"
        phx-click="add_form"
        phx-value-path={to_string(@nested.name)}
        phx-target={@target}
        class="btn-add-nested"
      >
        {@nested.add_label}
      </button>
    </fieldset>
    """
  end

  # ---------------------------------------------------------------------------
  # Private
  # ---------------------------------------------------------------------------

  defp theme_module do
    Application.get_env(:ash_form_builder, :theme, AshFormBuilder.Themes.Default)
  end
end
