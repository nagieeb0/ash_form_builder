defmodule AshFormBuilder.Themes.Default do
  @moduledoc """
  Default HTML theme for AshFormBuilder with production-ready Tailwind CSS styling.

  ## Features

  * **Zero Configuration** - Works out of the box with sensible defaults
  * **Tailwind CSS Classes** - Modern, clean styling without extra dependencies
  * **Accessible** - Proper labels, ARIA attributes, and focus states
  * **Responsive** - Mobile-friendly form fields
  * **Customizable** - Override classes via `theme_opts` config

  ## Configuration

      config :ash_form_builder,
        theme: AshFormBuilder.Themes.Default,
        theme_opts: [
          wrapper_class: "space-y-6",
          field_wrapper_class: "mb-4",
          label_class: "block text-sm font-medium text-gray-700 mb-1",
          input_class: "w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500",
          error_class: "text-sm text-red-600 mt-1",
          hint_class: "text-xs text-gray-500 mt-1"
        ]

  ## Field Types Supported

  * `:text_input`, `:textarea`, `:select`, `:checkbox`, `:number`, `:email`, `:password`
  * `:date`, `:datetime`, `:url`, `:tel`, `:hidden`
  * `:multiselect_combobox` - Fallback to multi-select (use MishkaTheme for combobox)
  * `:file_upload` - Phoenix LiveView file upload with drag-and-drop styling

  ## Custom Theme Example

      defmodule MyAppWeb.CustomTheme do
        @behaviour AshFormBuilder.Theme
        use Phoenix.Component

        @impl AshFormBuilder.Theme
        def render_field(assigns, opts) do
          # Your custom implementation
        end
      end

  See `guides/theme_customization_guide.md` for detailed customization instructions.
  """

  @behaviour AshFormBuilder.Theme

  use Phoenix.Component

  # ---------------------------------------------------------------------------
  # Public API - render_field/2
  # ---------------------------------------------------------------------------

  @impl AshFormBuilder.Theme
  def render_field(assigns, opts) do
    assigns = Map.put(assigns, :theme_opts, opts)

    case assigns.field.type do
      :hidden -> render_hidden(assigns)
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

  # ---------------------------------------------------------------------------
  # Multiselect combobox (fallback: styled multi-select)
  # ---------------------------------------------------------------------------

  defp render_multiselect_combobox(assigns) do
    ~H"""
    <div class={["mb-4", @field.wrapper_class]}>
      <label
        :if={@field.label}
        for={Phoenix.HTML.Form.input_id(@form, @field.name)}
        class="block text-sm font-medium text-gray-700 mb-1"
      >
        {@field.label}
        <span :if={@field.required} class="text-red-500 ml-1" aria-hidden="true">*</span>
      </label>

      <select
        id={Phoenix.HTML.Form.input_id(@form, @field.name)}
        name={Phoenix.HTML.Form.input_name(@form, @field.name) <> "[]"}
        class={[
          "w-full px-3 py-2 border rounded-md shadow-sm",
          "focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500",
          "bg-white text-gray-900",
          has_errors?(@form, @field.name) && "border-red-500 focus:ring-red-500 focus:border-red-500",
          @field.class
        ]}
        multiple
        size="5"
        aria-describedby={if @field.hint, do: "hint-#{Phoenix.HTML.Form.input_id(@form, @field.name)}"}
        aria-invalid={if has_errors?(@form, @field.name), do: "true", else: "false"}
      >
        <option value="" disabled>— Select multiple options —</option>
        <option
          :for={{label, value} <- normalize_options(@field.options)}
          value={to_string(value)}
          selected={to_string(Phoenix.HTML.Form.input_value(@form, @field.name)) == to_string(value)}
        >
          {label}
        </option>
      </select>

      <p
        :if={@field.hint}
        id={"hint-#{Phoenix.HTML.Form.input_id(@form, @field.name)}"}
        class="text-xs text-gray-500 mt-1"
      >
        {@field.hint}
      </p>

      <p
        :for={msg <- error_messages(@form, @field.name)}
        class="text-sm text-red-600 mt-1"
        role="alert"
      >
        {msg}
      </p>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Standard fields — wrapper + label + input + hint + errors
  # ---------------------------------------------------------------------------

  defp render_standard_field(assigns) do
    ~H"""
    <div class={["mb-4", @field.wrapper_class]}>
      <label
        :if={@field.label}
        for={Phoenix.HTML.Form.input_id(@form, @field.name)}
        class="block text-sm font-medium text-gray-700 mb-1"
      >
        {@field.label}
        <span :if={@field.required} class="text-red-500 ml-1" aria-hidden="true">*</span>
      </label>

      <.field_input form={@form} field={@field} has_errors={has_errors?(@form, @field.name)} />

      <p
        :if={@field.hint}
        id={"hint-#{Phoenix.HTML.Form.input_id(@form, @field.name)}"}
        class="text-xs text-gray-500 mt-1"
      >
        {@field.hint}
      </p>

      <p
        :for={msg <- error_messages(@form, @field.name)}
        class="text-sm text-red-600 mt-1"
        role="alert"
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
  attr(:has_errors, :boolean, default: false)

  defp field_input(%{field: %AshFormBuilder.Field{type: :textarea}} = assigns) do
    ~H"""
    <textarea
      id={Phoenix.HTML.Form.input_id(@form, @field.name)}
      name={Phoenix.HTML.Form.input_name(@form, @field.name)}
      placeholder={@field.placeholder}
      rows="4"
      class={[
        "w-full px-3 py-2 border rounded-md shadow-sm",
        "focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500",
        "font-mono text-sm",
        @has_errors && "border-red-500 focus:ring-red-500 focus:border-red-500",
        @field.class
      ]}
    ><%= Phoenix.HTML.Form.input_value(@form, @field.name) %></textarea>
    """
  end

  defp field_input(%{field: %AshFormBuilder.Field{type: :select}} = assigns) do
    ~H"""
    <select
      id={Phoenix.HTML.Form.input_id(@form, @field.name)}
      name={Phoenix.HTML.Form.input_name(@form, @field.name)}
      class={[
        "w-full px-3 py-2 border rounded-md shadow-sm",
        "focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500",
        "bg-white text-gray-900",
        @has_errors && "border-red-500 focus:ring-red-500 focus:border-red-500",
        @field.class
      ]}
    >
      <option value="">— Select an option —</option>
      <option
        :for={{label, value} <- normalize_options(@field.options)}
        value={to_string(value)}
        selected={to_string(Phoenix.HTML.Form.input_value(@form, @field.name)) == to_string(value)}
      >
        {label}
      </option>
    </select>
    """
  end

  defp field_input(%{field: %AshFormBuilder.Field{type: :checkbox}} = assigns) do
    ~H"""
    <div class="flex items-start">
      <div class="flex items-center h-5">
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
          class={[
            "h-4 w-4 text-blue-600 border-gray-300 rounded",
            "focus:ring-2 focus:ring-blue-500 focus:ring-offset-0",
            @has_errors && "border-red-500 focus:ring-red-500",
            @field.class
          ]}
        />
      </div>
      <label
        :if={@field.label}
        for={Phoenix.HTML.Form.input_id(@form, @field.name)}
        class="ml-2 block text-sm text-gray-900"
      >
        {@field.label}
        <span :if={@field.required} class="text-red-500 ml-1" aria-hidden="true">*</span>
      </label>
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
      class={[
        "w-full px-3 py-2 border rounded-md shadow-sm",
        "focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500",
        "text-gray-900 placeholder-gray-400",
        @has_errors && "border-red-500 focus:ring-red-500 focus:border-red-500",
        @field.class
      ]}
      phx-debounce="300"
    />
    """
  end

  # ---------------------------------------------------------------------------
  # File Upload — Styled with Tailwind
  # ---------------------------------------------------------------------------

  defp render_file_upload(assigns) do
    ~H"""
    <div class={["mb-4", @field.wrapper_class]}>
      <label :if={@field.label} class="block text-sm font-medium text-gray-700 mb-1">
        {@field.label}
        <span :if={@field.required} class="text-red-500 ml-1" aria-hidden="true">*</span>
      </label>

      <div
        :if={@upload_config}
        class={[
          "border-2 border-dashed rounded-lg p-6",
          "hover:border-blue-500 transition-colors",
          has_errors?(@form, @field.name) && "border-red-500 hover:border-red-500",
          is_nil(@upload_config) && "border-gray-300 bg-gray-50"
        ]}
      >
        <.live_file_input
          upload={@upload_config}
          class="block w-full text-sm text-gray-500
                 file:mr-4 file:py-2 file:px-4
                 file:rounded-md file:border-0
                 file:text-sm file:font-semibold
                 file:bg-blue-50 file:text-blue-700
                 hover:file:bg-blue-100"
        />

        <div :if={length(@upload_config.entries) > 0} class="mt-4 space-y-3">
          <%= for entry <- @upload_config.entries do %>
            <div class="flex items-start gap-3 p-3 bg-gray-50 rounded-md">
              <.live_img_preview
                entry={entry}
                class="h-16 w-16 rounded object-cover border border-gray-200 flex-shrink-0"
              />
              <div class="flex-1 min-w-0">
                <p class="text-sm font-medium text-gray-700 truncate">{entry.client_name}</p>
                <div class="mt-1 h-2 w-full rounded-full bg-gray-200">
                  <div
                    class="h-2 rounded-full bg-blue-500 transition-all"
                    style={"width: #{entry.progress}%"}
                  ></div>
                </div>
                <p class="text-xs text-gray-500 mt-1">{entry.progress}%</p>
                <%= for {ref, err} <- @upload_config.errors, ref == entry.ref do %>
                  <p class="text-xs text-red-600 mt-1">{upload_error_message(err)}</p>
                <% end %>
              </div>
            </div>
          <% end %>
        </div>

        <div :if={length(@upload_config.errors) > 0} class="mt-3">
          <%= for {_ref, err} <- @upload_config.errors do %>
            <p class="text-sm text-red-600">{upload_error_message(err)}</p>
          <% end %>
        </div>
      </div>

      <div :if={is_nil(@upload_config)} class="border rounded-lg p-6 text-center">
        <p class="text-sm text-gray-500">File upload not configured for this field</p>
      </div>

      <p :if={@field.hint} class="text-xs text-gray-500 mt-1">{@field.hint}</p>

      <p :for={msg <- error_messages(@form, @field.name)} class="text-sm text-red-600 mt-1" role="alert">
        {msg}
      </p>
    </div>
    """
  end

  defp upload_error_message(:too_large), do: "File is too large"
  defp upload_error_message(:too_many_files), do: "Too many files selected"
  defp upload_error_message(:not_accepted), do: "File type not accepted"
  defp upload_error_message(err), do: "Upload error: #{inspect(err)}"

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp normalize_options(options) when is_list(options) do
    Enum.map(options, fn
      {label, value} -> {label, value}
      value -> {to_string(value), value}
    end)
  end

  defp normalize_options(_), do: []

  defp error_messages(form, field_name) do
    cond do
      not is_map(form) ->
        []

      not Map.has_key?(form, field_name) ->
        []

      is_nil(form[field_name]) ->
        []

      true ->
        field = form[field_name]
        if is_map(field), do: Keyword.get_values(field.errors, :message), else: []
    end
  end

  defp has_errors?(form, field_name) do
    error_messages(form, field_name) != []
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
