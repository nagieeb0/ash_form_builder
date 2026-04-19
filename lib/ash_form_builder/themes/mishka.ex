defmodule AshFormBuilder.Themes.Mishka do
  @moduledoc """
  Example MishkaChelekom theme for AshFormBuilder.

  ## Setup

  1. Generate the required mishka_chelekom components in your Phoenix app:

         mix mishka.ui.gen.component text_field
         mix mishka.ui.gen.component textarea_field
         mix mishka.ui.gen.component native_select
         mix mishka.ui.gen.component checkbox_field
         mix mishka.ui.gen.component number_field
         mix mishka.ui.gen.component email_field
         mix mishka.ui.gen.component password_field
         mix mishka.ui.gen.component date_time_field
         mix mishka.ui.gen.component url_field

  2. Copy this module into your app (e.g. `lib/my_app_web/form_builder/mishka_theme.ex`),
     update the module name and the `import` statement to match your generated module path,
     then activate it:

         # config/config.exs
         config :ash_form_builder, :theme, MyAppWeb.FormBuilder.MishkaTheme

  ## Notes

  - Mishka components accept a `color` and `variant` prop — adjust the defaults below
    to match your design system.
  - The `<.native_select>` component is used for `:select` fields. If you prefer
    `<.combobox>` for searchable dropdowns, swap it in `render_field/1`.
  - Error rendering uses `@form[@field.name].errors` — Mishka components typically
    accept an `errors` prop; wire it as shown in the `render_field` clause.
  """

  @behaviour AshFormBuilder.Theme

  use Phoenix.Component

  # Import the generated mishka components from your application.
  # Replace `MyAppWeb.Components` with the actual path in your project.
  #
  # import MyAppWeb.Components.TextFieldComponent
  # import MyAppWeb.Components.TextareaFieldComponent
  # import MyAppWeb.Components.NativeSelectComponent
  # import MyAppWeb.Components.CheckboxFieldComponent
  # import MyAppWeb.Components.NumberFieldComponent
  # import MyAppWeb.Components.EmailFieldComponent
  # import MyAppWeb.Components.PasswordFieldComponent
  # import MyAppWeb.Components.DateTimeFieldComponent
  # import MyAppWeb.Components.UrlFieldComponent

  # ---------------------------------------------------------------------------
  # Hidden field — no wrapper needed
  # ---------------------------------------------------------------------------

  @impl AshFormBuilder.Theme
  def render_field(assigns, _opts \\ []) do
    case assigns.field.type do
      :hidden -> render_hidden(assigns)
      :textarea -> render_textarea(assigns)
      :select -> render_select(assigns)
      :checkbox -> render_checkbox(assigns)
      _ -> render_default(assigns)
    end
  end

  defp render_hidden(assigns) do
    ~H"""
    <input
      type="hidden"
      id={Phoenix.HTML.Form.input_id(@form, @field.name)}
      name={Phoenix.HTML.Form.input_name(@form, @field.name)}
      value={Phoenix.HTML.Form.input_value(@form, @field.name)}
    />
    """
  end

  defp render_textarea(assigns) do
    ~H"""
    <%!-- Replace with: <.textarea_field .../> once component is generated --%>
    <div class="mb-4">
      <label :if={@field.label} class="block text-sm font-medium mb-1">
        {@field.label}
        <span :if={@field.required} class="text-error ml-1">*</span>
      </label>
      <textarea
        id={Phoenix.HTML.Form.input_id(@form, @field.name)}
        name={Phoenix.HTML.Form.input_name(@form, @field.name)}
        placeholder={@field.placeholder}
        class="textarea textarea-bordered w-full"
        rows="4"
      ><%= Phoenix.HTML.Form.input_value(@form, @field.name) %></textarea>
      <.field_hint hint={@field.hint} />
      <.field_errors form={@form} field={@field} />
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Select / dropdown
  # ---------------------------------------------------------------------------

  defp render_select(assigns) do
    ~H"""
    <%!-- Replace with: <.native_select .../> once component is generated --%>
    <div class="mb-4">
      <label :if={@field.label} class="block text-sm font-medium mb-1">
        {@field.label}
        <span :if={@field.required} class="text-error ml-1">*</span>
      </label>
      <select
        id={Phoenix.HTML.Form.input_id(@form, @field.name)}
        name={Phoenix.HTML.Form.input_name(@form, @field.name)}
        class="select select-bordered w-full"
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
      <.field_hint hint={@field.hint} />
      <.field_errors form={@form} field={@field} />
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Checkbox / toggle
  # ---------------------------------------------------------------------------

  defp render_checkbox(assigns) do
    ~H"""
    <%!-- Replace with: <.toggle_field .../> or <.checkbox_field .../> --%>
    <div class="mb-4 flex items-center gap-2">
      <input type="hidden" name={Phoenix.HTML.Form.input_name(@form, @field.name)} value="false" />
      <input
        type="checkbox"
        id={Phoenix.HTML.Form.input_id(@form, @field.name)}
        name={Phoenix.HTML.Form.input_name(@form, @field.name)}
        value="true"
        checked={Phoenix.HTML.Form.input_value(@form, @field.name) in [true, "true"]}
        class="checkbox checkbox-primary"
      />
      <label :if={@field.label} for={Phoenix.HTML.Form.input_id(@form, @field.name)} class="text-sm">
        {@field.label}
        <span :if={@field.required} class="text-error ml-1">*</span>
      </label>
      <.field_errors form={@form} field={@field} />
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # All other inputs (text, number, email, password, date, url, tel)
  # ---------------------------------------------------------------------------

  defp render_default(assigns) do
    ~H"""
    <%!-- Replace with: <.text_field .../>, <.number_field .../>, etc. --%>
    <div class="mb-4">
      <label :if={@field.label} class="block text-sm font-medium mb-1">
        {@field.label}
        <span :if={@field.required} class="text-error ml-1">*</span>
      </label>
      <input
        type={html_input_type(@field.type)}
        id={Phoenix.HTML.Form.input_id(@form, @field.name)}
        name={Phoenix.HTML.Form.input_name(@form, @field.name)}
        value={Phoenix.HTML.Form.input_value(@form, @field.name)}
        placeholder={@field.placeholder}
        class={["input input-bordered w-full", @field.class]}
        phx-debounce="300"
      />
      <.field_hint hint={@field.hint} />
      <.field_errors form={@form} field={@field} />
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Shared sub-components
  # ---------------------------------------------------------------------------

  attr(:hint, :string, default: nil)

  defp field_hint(%{hint: nil} = assigns), do: ~H""
  defp field_hint(assigns), do: ~H"<p class='text-xs text-base-content/60 mt-1'>{@hint}</p>"

  attr(:form, Phoenix.HTML.Form, required: true)
  attr(:field, :any, required: true)

  defp field_errors(assigns) do
    ~H"""
    <p
      :for={
        {msg, _opts} <-
          Keyword.get_values((@form[@field.name] || %{errors: []}).errors, :message)
      }
      class="text-xs text-error mt-1"
    >
      {msg}
    </p>
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
