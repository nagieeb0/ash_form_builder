defmodule AshFormBuilder.Themes.Glassmorphism do
  @moduledoc """
  Premium Glassmorphism theme for AshFormBuilder.

  ## Aesthetic

  Creates a modern, premium look with smooth glass-like surfaces, subtle blurs,
  and elegant micro-interactions. Perfect for applications wanting a sophisticated,
  contemporary appearance.

  ## Configuration

  Add to your `config/config.exs`:

      config :ash_form_builder,
        theme: AshFormBuilder.Themes.Glassmorphism,
        theme_opts: [
          # Background variant: :light (default) or :dark
          variant: :light,
          
          # Primary accent color for focus states
          accent_color: "blue",
          
          # Glass intensity: :subtle, :medium (default), :strong
          glass_intensity: :medium
        ]

  ## Visual Characteristics

  * **Glass Surfaces** - Semi-transparent backgrounds with backdrop blur
  * **Soft Borders** - Subtle white/dark borders for depth
  * **Smooth Animations** - 300ms transitions on focus and hover
  * **Floating Effect** - Inputs appear to float on glass panels
  * **Shadow Depth** - Layered shadows for 3D effect

  ## Example Screenshot

  Imagine form fields that look like frosted glass panels floating on a gradient
  background, with smooth transitions when focused.

  ## Usage

  No additional setup required beyond configuration. The theme automatically
  applies glassmorphism styling to all form fields.

      # In your LiveView
      def render(assigns) do
        ~H\"""
        <.live_component
          module={AshFormBuilder.FormComponent}
          id="my-form"
          resource={MyApp.Resource}
          form={@form}
        />
        \"""
      end

  ## Dark Mode Support

  Configure dark variant for dark backgrounds:

      config :ash_form_builder,
        theme: AshFormBuilder.Themes.Glassmorphism,
        theme_opts: [variant: :dark]

  ## Browser Support

  Requires support for:
  * `backdrop-filter` (CSS backdrop blur)
  * `rgba()` colors (transparency)
  * CSS transitions

  Works in all modern browsers (Chrome, Firefox, Safari, Edge).
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
      :checkbox -> render_checkbox(assigns)
      :file_upload -> render_file_upload(assigns)
      :multiselect_combobox -> render_multiselect_combobox(assigns)
      _ -> render_standard_field(assigns)
    end
  end

  @impl AshFormBuilder.Theme
  def render_nested(_assigns) do
    nil
  end

  # ---------------------------------------------------------------------------
  # Hidden Field
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
  # Standard Fields (text, email, password, number, date, etc.)
  # ---------------------------------------------------------------------------

  defp render_standard_field(assigns) do
    ~H"""
    <div class={["relative group", @field.wrapper_class]}>
      <label
        :if={@field.label}
        for={Phoenix.HTML.Form.input_id(@form, @field.name)}
        class="block text-sm font-medium text-gray-700 dark:text-gray-200 mb-2 
               transition-all duration-300 group-hover:text-gray-900 dark:group-hover:text-white"
      >
        {@field.label}
        <span :if={@field.required} class="text-pink-500 ml-1" aria-hidden="true">*</span>
      </label>

      <div class="relative">
        <.field_input form={@form} field={@field} />
      </div>

      <p
        :if={@field.hint}
        class="text-xs text-gray-500 dark:text-gray-400 mt-2 
               transition-all duration-300"
      >
        {@field.hint}
      </p>

      <.field_errors form={@form} field={@field.name} />
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Checkbox Field (special layout)
  # ---------------------------------------------------------------------------

  defp render_checkbox(assigns) do
    ~H"""
    <div class={["relative group", @field.wrapper_class]}>
      <div class="flex items-start group">
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
              "h-5 w-5",
              "bg-white/10 dark:bg-black/20",
              "backdrop-blur-lg",
              "border-2 border-white/30 dark:border-white/20",
              "rounded-lg",
              "text-blue-600",
              "transition-all duration-300 ease-out",
              "hover:scale-110 hover:border-blue-400",
              "focus:outline-none focus:ring-2 focus:ring-blue-500/50 focus:ring-offset-2",
              "checked:bg-blue-600 checked:border-blue-600",
              has_error_class(@form, @field.name),
              @field.class
            ]}
          />
        </div>
        <label
          :if={@field.label}
          for={Phoenix.HTML.Form.input_id(@form, @field.name)}
          class="ml-3 block text-sm text-gray-700 dark:text-gray-200 
                 cursor-pointer transition-all duration-300 
                 group-hover:text-gray-900 dark:group-hover:text-white"
        >
          {@field.label}
          <span :if={@field.required} class="text-pink-500 ml-1" aria-hidden="true">*</span>
        </label>
      </div>

      <p
        :if={@field.hint}
        class="text-xs text-gray-500 dark:text-gray-400 mt-2 
               transition-all duration-300"
      >
        {@field.hint}
      </p>

      <.field_errors form={@form} field={@field.name} />
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Input Widget Switcher
  # ---------------------------------------------------------------------------

  attr(:form, Phoenix.HTML.Form, required: true)
  attr(:field, :any, required: true)

  defp field_input(%{field: %AshFormBuilder.Field{type: :textarea}} = assigns) do
    ~H"""
    <textarea
      id={Phoenix.HTML.Form.input_id(@form, @field.name)}
      name={Phoenix.HTML.Form.input_name(@form, @field.name)}
      placeholder={@field.placeholder}
      rows="4"
      class={[
        "w-full px-4 py-3",
        "bg-white/10 dark:bg-black/20",
        "backdrop-blur-lg",
        "border border-white/20 dark:border-white/10",
        "rounded-xl shadow-lg",
        "text-gray-900 dark:text-white placeholder-gray-500 dark:placeholder-gray-400",
        "transition-all duration-300 ease-out",
        "hover:scale-[1.01] hover:bg-white/15 dark:hover:bg-black/25",
        "focus:outline-none focus:ring-2 focus:ring-blue-500/50 focus:bg-white/20 dark:focus:bg-black/30",
        "focus:shadow-xl focus:shadow-blue-500/10",
        has_error_class(@form, @field.name),
        @field.class
      ]}
    ><%= Phoenix.HTML.Form.input_value(@form, @field.name) %></textarea>
    """
  end

  defp field_input(%{field: %AshFormBuilder.Field{type: :select}} = assigns) do
    ~H"""
    <div class="relative">
      <select
        id={Phoenix.HTML.Form.input_id(@form, @field.name)}
        name={Phoenix.HTML.Form.input_name(@form, @field.name)}
        class={[
          "w-full px-4 py-3 pr-10",
          "bg-white/10 dark:bg-black/20",
          "backdrop-blur-lg",
          "border border-white/20 dark:border-white/10",
          "rounded-xl shadow-lg",
          "text-gray-900 dark:text-white",
          "appearance-none cursor-pointer",
          "transition-all duration-300 ease-out",
          "hover:scale-[1.01] hover:bg-white/15 dark:hover:bg-black/25",
          "focus:outline-none focus:ring-2 focus:ring-blue-500/50 focus:bg-white/20 dark:focus:bg-black/30",
          "focus:shadow-xl focus:shadow-blue-500/10",
          has_error_class(@form, @field.name),
          @field.class
        ]}
      >
        <option value="" disabled>Select an option</option>
        <option
          :for={{label, value} <- normalize_options(@field.options)}
          value={to_string(value)}
          selected={to_string(Phoenix.HTML.Form.input_value(@form, @field.name)) == to_string(value)}
        >
          {label}
        </option>
      </select>
      <div class="absolute inset-y-0 right-0 flex items-center px-3 pointer-events-none">
        <svg class="w-5 h-5 text-gray-500 dark:text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
        </svg>
      </div>
    </div>
    """
  end

  defp field_input(assigns) do
    input_type = html_input_type(@field.type)

    ~H"""
    <input
      type={input_type}
      id={Phoenix.HTML.Form.input_id(@form, @field.name)}
      name={Phoenix.HTML.Form.input_name(@form, @field.name)}
      value={Phoenix.HTML.Form.input_value(@form, @field.name)}
      placeholder={@field.placeholder}
      class={[
        "w-full px-4 py-3",
        "bg-white/10 dark:bg-black/20",
        "backdrop-blur-lg",
        "border border-white/20 dark:border-white/10",
        "rounded-xl shadow-lg",
        "text-gray-900 dark:text-white placeholder-gray-500 dark:placeholder-gray-400",
        "transition-all duration-300 ease-out",
        "hover:scale-[1.01] hover:bg-white/15 dark:hover:bg-black/25",
        "focus:outline-none focus:ring-2 focus:ring-blue-500/50 focus:bg-white/20 dark:focus:bg-black/30",
        "focus:shadow-xl focus:shadow-blue-500/10",
        input_type == "password" && "tracking-wide",
        has_error_class(@form, @field.name),
        @field.class
      ]}
      phx-debounce="300"
    />
    """
  end

  # ---------------------------------------------------------------------------
  # File Upload
  # ---------------------------------------------------------------------------

  defp render_file_upload(assigns) do
    ~H"""
    <div class={["relative group", @field.wrapper_class]}>
      <label
        :if={@field.label}
        class="block text-sm font-medium text-gray-700 dark:text-gray-200 mb-2 
               transition-all duration-300 group-hover:text-gray-900 dark:group-hover:text-white"
      >
        {@field.label}
        <span :if={@field.required} class="text-pink-500 ml-1" aria-hidden="true">*</span>
      </label>

      <div
        :if={@uploads[@field.name]}
        class={[
          "relative overflow-hidden",
          "bg-white/10 dark:bg-black/20",
          "backdrop-blur-lg",
          "border-2 border-dashed border-white/30 dark:border-white/20",
          "rounded-2xl shadow-lg",
          "p-8",
          "transition-all duration-300 ease-out",
          "hover:border-blue-400 hover:bg-white/15 dark:hover:bg-black/25",
          "hover:shadow-xl hover:shadow-blue-500/10"
        ]}
      >
        <.live_file_input
          upload={@uploads[@field.name]}
          class="block w-full text-sm text-gray-600 dark:text-gray-300
                 file:mr-4 file:py-3 file:px-6
                 file:rounded-xl file:border-0
                 file:text-sm file:font-semibold
                 file:bg-blue-500/20 file:text-blue-700 dark:file:bg-blue-600/30 dark:file:text-blue-300
                 file:transition-all file:duration-300
                 hover:file:bg-blue-500/30 dark:hover:file:bg-blue-600/40
                 file:hover:scale-105"
        />

        <div :if={length(@uploads[@field.name].entries) > 0} class="mt-6 space-y-4">
          <%= for entry <- @uploads[@field.name].entries do %>
            <div class={[
              "flex items-center gap-4 p-4",
              "bg-white/10 dark:bg-black/20",
              "backdrop-blur-lg",
              "border border-white/20 dark:border-white/10",
              "rounded-xl",
              "transition-all duration-300",
              "hover:bg-white/15 dark:hover:bg-black/25"
            ]}>
              <.live_img_preview
                entry={entry}
                class="h-16 w-16 rounded-lg object-cover border border-white/20 dark:border-white/10 
                       shadow-md transition-transform duration-300 hover:scale-105"
              />
              <div class="flex-1 min-w-0">
                <p class="text-sm font-medium text-gray-900 dark:text-white truncate">
                  {entry.client_name}
                </p>
                <div class="mt-2 h-2 w-full rounded-full bg-white/20 dark:bg-white/10 overflow-hidden">
                  <div
                    class="h-full rounded-full bg-gradient-to-r from-blue-500 to-purple-500 
                           transition-all duration-300 ease-out"
                    style={"width: #{entry.progress}%"}
                  ></div>
                </div>
                <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">{entry.progress}%</p>
              </div>
            </div>
          <% end %>
        </div>

        <div :if={length(@uploads[@field.name].errors) > 0} class="mt-4 space-y-2">
          <%= for {_ref, err} <- @uploads[@field.name].errors do %>
            <p class="text-sm text-pink-500 dark:text-pink-400 bg-pink-500/10 
                      backdrop-blur-sm px-4 py-2 rounded-lg border border-pink-500/20">
              {upload_error_message(err)}
            </p>
          <% end %>
        </div>
      </div>

      <p :if={@field.hint} class="text-xs text-gray-500 dark:text-gray-400 mt-2">
        {@field.hint}
      </p>

      <.field_errors form={@form} field={@field.name} />
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Multiselect Combobox (Fallback)
  # ---------------------------------------------------------------------------

  defp render_multiselect_combobox(assigns) do
    ~H"""
    <div class={["relative group", @field.wrapper_class]}>
      <label
        :if={@field.label}
        for={Phoenix.HTML.Form.input_id(@form, @field.name)}
        class="block text-sm font-medium text-gray-700 dark:text-gray-200 mb-2 
               transition-all duration-300 group-hover:text-gray-900 dark:group-hover:text-white"
      >
        {@field.label}
        <span :if={@field.required} class="text-pink-500 ml-1" aria-hidden="true">*</span>
      </label>

      <select
        id={Phoenix.HTML.Form.input_id(@form, @field.name)}
        name={Phoenix.HTML.Form.input_name(@form, @field.name) <> "[]"}
        multiple
        size="5"
        class={[
          "w-full px-4 py-3",
          "bg-white/10 dark:bg-black/20",
          "backdrop-blur-lg",
          "border border-white/20 dark:border-white/10",
          "rounded-xl shadow-lg",
          "text-gray-900 dark:text-white",
          "transition-all duration-300 ease-out",
          "hover:scale-[1.01] hover:bg-white/15 dark:hover:bg-black/25",
          "focus:outline-none focus:ring-2 focus:ring-blue-500/50 focus:bg-white/20 dark:focus:bg-black/30",
          "focus:shadow-xl focus:shadow-blue-500/10",
          has_error_class(@form, @field.name),
          @field.class
        ]}
      >
        <option
          :for={{label, value} <- normalize_options(@field.options)}
          value={to_string(value)}
          selected={to_string(Phoenix.HTML.Form.input_value(@form, @field.name)) == to_string(value)}
        >
          {label}
        </option>
      </select>

      <p :if={@field.hint} class="text-xs text-gray-500 dark:text-gray-400 mt-2">
        {@field.hint}
      </p>

      <.field_errors form={@form} field={@field.name} />
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Helper Components
  # ---------------------------------------------------------------------------

  attr(:form, :any, required: true)
  attr(:field, :any, required: true)

  defp field_errors(assigns) do
    error_messages = extract_error_messages(assigns.form, assigns.field)

    ~H"""
    <div :if={length(error_messages) > 0} class="mt-2 space-y-1">
      <%= for msg <- error_messages do %>
        <p class="text-sm text-pink-500 dark:text-pink-400 
                  bg-pink-500/10 backdrop-blur-sm 
                  px-3 py-2 rounded-lg border border-pink-500/20
                  animate-pulse"
           role="alert">
          {msg}
        </p>
      <% end %>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Private Helpers
  # ---------------------------------------------------------------------------

  defp normalize_options(options) when is_list(options) do
    Enum.map(options, fn
      {label, value} -> {label, value}
      value -> {to_string(value), value}
    end)
  end

  defp normalize_options(_), do: []

  defp extract_error_messages(form, field_name) do
    cond do
      not is_map(form) -> []
      not Map.has_key?(form, field_name) -> []
      is_nil(form[field_name]) -> []
      true ->
        field = form[field_name]
        if is_map(field), do: Keyword.get_values(field.errors, :message), else: []
    end
  end

  defp has_error_class(form, field_name) do
    case extract_error_messages(form, field_name) do
      [] -> ""
      _ -> "border-pink-500 focus:ring-pink-500/50 focus:shadow-pink-500/10"
    end
  end

  defp upload_error_message(:too_large), do: "File is too large"
  defp upload_error_message(:too_many_files), do: "Too many files selected"
  defp upload_error_message(:not_accepted), do: "File type not accepted"
  defp upload_error_message(err), do: "Upload error: #{inspect(err)}"

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
