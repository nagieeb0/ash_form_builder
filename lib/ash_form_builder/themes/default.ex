defmodule AshFormBuilder.Themes.Default do
  @moduledoc """
  Default HTML theme for AshFormBuilder.

  Emits semantic HTML with minimal CSS class hooks — no framework dependency.
  Override via `config :ash_form_builder, :theme, MyApp.MyTheme`.
  """

  @behaviour AshFormBuilder.Theme

  use Phoenix.Component

  # ---------------------------------------------------------------------------
  # Hidden field — no wrapper, no label
  # ---------------------------------------------------------------------------

  @impl AshFormBuilder.Theme
  def render_field(%{field: %AshFormBuilder.Field{type: :hidden}} = assigns) do
    ~H"""
    <input
      type="hidden"
      id={Phoenix.HTML.Form.input_id(@form, @field.name)}
      name={Phoenix.HTML.Form.input_name(@form, @field.name)}
      value={Phoenix.HTML.Form.input_value(@form, @field.name)}
    />
    """
  end

  # ---------------------------------------------------------------------------
  # All other fields — wrapper + label + input + hint + errors
  # ---------------------------------------------------------------------------

  def render_field(assigns) do
    ~H"""
    <div class={["form-group", @field.wrapper_class]}>
      <label
        :if={@field.label}
        for={Phoenix.HTML.Form.input_id(@form, @field.name)}
        class="form-label"
      >
        {@field.label}
        <span :if={@field.required} aria-hidden="true" class="required-mark"> *</span>
      </label>

      <.field_input form={@form} field={@field} />

      <p :if={@field.hint} class="form-hint">{@field.hint}</p>

      <p
        :for={
          {msg, _opts} <-
            Keyword.get_values((@form[@field.name] || %{errors: []}).errors, :message)
        }
        class="form-error"
      >
        {msg}
      </p>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Input widget switcher (private)
  # ---------------------------------------------------------------------------

  attr(:form, Phoenix.HTML.Form, required: true)
  attr(:field, :any, required: true)

  defp field_input(%{field: %AshFormBuilder.Field{type: :textarea}} = assigns) do
    ~H"""
    <textarea
      id={Phoenix.HTML.Form.input_id(@form, @field.name)}
      name={Phoenix.HTML.Form.input_name(@form, @field.name)}
      placeholder={@field.placeholder}
      class={["form-textarea", @field.class]}
      phx-debounce="300"
    ><%= Phoenix.HTML.Form.input_value(@form, @field.name) %></textarea>
    """
  end

  defp field_input(%{field: %AshFormBuilder.Field{type: :select}} = assigns) do
    ~H"""
    <select
      id={Phoenix.HTML.Form.input_id(@form, @field.name)}
      name={Phoenix.HTML.Form.input_name(@form, @field.name)}
      class={["form-select", @field.class]}
    >
      <option value="">— select —</option>
      <option
        :for={{label, value} <- normalize_options(@field.options)}
        value={to_string(value)}
        selected={
          to_string(Phoenix.HTML.Form.input_value(@form, @field.name)) == to_string(value)
        }
      >
        {label}
      </option>
    </select>
    """
  end

  defp field_input(%{field: %AshFormBuilder.Field{type: :checkbox}} = assigns) do
    ~H"""
    <div class="form-checkbox-wrapper">
      <input
        type="hidden"
        name={Phoenix.HTML.Form.input_name(@form, @field.name)}
        value="false"
      />
      <input
        type="checkbox"
        id={Phoenix.HTML.Form.input_id(@form, @field.name)}
        name={Phoenix.HTML.Form.input_name(@form, @field.name)}
        value="true"
        checked={Phoenix.HTML.Form.input_value(@form, @field.name) in [true, "true"]}
        class={["form-checkbox", @field.class]}
      />
    </div>
    """
  end

  defp field_input(assigns) do
    ~H"""
    <input
      type={html_input_type(@field.type)}
      id={Phoenix.HTML.Form.input_id(@form, @field.name)}
      name={Phoenix.HTML.Form.input_name(@form, @field.name)}
      value={Phoenix.HTML.Form.input_value(@form, @field.name)}
      placeholder={@field.placeholder}
      class={["form-input", @field.class]}
      phx-debounce="300"
    />
    """
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp normalize_options(options) do
    Enum.map(options, fn
      {label, value} -> {label, value}
      value -> {to_string(value), value}
    end)
  end

  defp html_input_type(:text_input), do: "text"
  defp html_input_type(:number), do: "number"
  defp html_input_type(:email), do: "email"
  defp html_input_type(:password), do: "password"
  defp html_input_type(:date), do: "date"
  defp html_input_type(:datetime), do: "datetime-local"
  defp html_input_type(:url), do: "url"
  defp html_input_type(:tel), do: "tel"
  defp html_input_type(_), do: "text"
end
