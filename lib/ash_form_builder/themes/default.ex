defmodule AshFormBuilder.Themes.Default do
  @moduledoc """
  Default HTML theme for AshFormBuilder.

  Emits semantic HTML with minimal CSS class hooks — no framework dependency.
  Override via `config :ash_form_builder, :theme, MyApp.MyTheme`.

  ## Field Types Supported

  * `:text_input`, `:textarea`, `:select`, `:checkbox`, `:number`, `:email`, `:password`
  * `:date`, `:datetime`, `:url`, `:tel`, `:hidden`
  * `:multiselect_combobox` - Falls back to multi-select (themes should override)
  """

  @behaviour AshFormBuilder.Theme

  use Phoenix.Component

  # ---------------------------------------------------------------------------
  # Public API - render_field/2
  # ---------------------------------------------------------------------------

  @impl AshFormBuilder.Theme
  def render_field(assigns, opts) do
    assigns = Map.put(assigns, :opts, opts)

    case assigns.field.type do
      :hidden -> render_hidden_field(assigns)
      :multiselect_combobox -> render_multiselect_combobox(assigns)
      :file_upload -> render_file_upload(assigns)
      _ -> render_standard_field(assigns)
    end
  end

  @impl AshFormBuilder.Theme
  def render_nested(_assigns) do
    # Return nil to use default nested form rendering in FormRenderer
    nil
  end

  # ---------------------------------------------------------------------------
  # Hidden field — no wrapper, no label
  # ---------------------------------------------------------------------------

  defp render_hidden_field(assigns) do
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
  # Multiselect combobox (fallback implementation)
  # ---------------------------------------------------------------------------

  defp render_multiselect_combobox(assigns) do
    # Default theme uses a multi-select as fallback
    # MishkaTheme provides the full combobox implementation
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

      <select
        id={Phoenix.HTML.Form.input_id(@form, @field.name)}
        name={Phoenix.HTML.Form.input_name(@form, @field.name) <> "[]"}
        class={["form-select", @field.class]}
        multiple
        size="4"
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
  # All other fields — wrapper + label + input + hint + errors
  # ---------------------------------------------------------------------------

  defp render_standard_field(assigns) do
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
  # File Upload
  # ---------------------------------------------------------------------------

  defp render_file_upload(assigns) do
    upload_config = assigns.uploads[assigns.field.name]
    assigns = Map.put(assigns, :upload_config, upload_config)

    ~H"""
    <div class={["form-group", @field.wrapper_class]}>
      <label :if={@field.label} class="form-label">
        {@field.label}
        <span :if={@field.required} aria-hidden="true" class="required-mark"> *</span>
      </label>

      <div :if={@upload_config} class="file-upload-zone">
        <.live_file_input upload={@upload_config} />

        <%= for entry <- @upload_config.entries do %>
          <div class="upload-entry">
            <.live_img_preview entry={entry} class="upload-preview" />
            <div class="upload-progress">
              <div class="upload-progress-bar" style={"width: #{entry.progress}%"}></div>
              <span class="upload-progress-text">{entry.progress}%</span>
            </div>
            <%= for {ref, err} <- @upload_config.errors, ref == entry.ref do %>
              <p class="form-error">{upload_error_message(err)}</p>
            <% end %>
          </div>
        <% end %>

        <%= for {_ref, err} <- @upload_config.errors do %>
          <p class="form-error">{upload_error_message(err)}</p>
        <% end %>
      </div>

      <div :if={is_nil(@upload_config)} class="file-upload-unavailable">
        <p class="form-hint">File upload not configured</p>
      </div>

      <p :if={@field.hint} class="form-hint">{@field.hint}</p>
    </div>
    """
  end

  defp upload_error_message(:too_large), do: "File is too large"
  defp upload_error_message(:too_many_files), do: "Too many files selected"
  defp upload_error_message(:not_accepted), do: "File type not accepted"
  defp upload_error_message(err), do: "Upload error: #{err}"

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
