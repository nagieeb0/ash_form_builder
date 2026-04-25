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

    # Auto-promote long text inputs to textarea when max_length > 255
    field = assigns.field

    field =
      if field.type == :text_input and
           is_integer(Keyword.get(field.opts || [], :max_length, 0)) and
           Keyword.get(field.opts || [], :max_length, 0) > 255 do
        %{field | type: :textarea}
      else
        field
      end

    assigns = Map.put(assigns, :field, field)

    case assigns.field.type do
      :hidden -> render_hidden(assigns)
      t when t in [:boolean, :checkbox] -> render_toggle(assigns)
      :array -> render_array_field(assigns)
      :file_upload -> render_file_upload(assigns)
      :multiselect_combobox -> render_multiselect_combobox(assigns)
      _ -> render_standard_field(assigns)
    end
  end

  # ---------------------------------------------------------------------------
  # Nested Form - themed glassmorphism rendering
  # ---------------------------------------------------------------------------

  @impl AshFormBuilder.Theme
  def render_nested(assigns) do
    ~H"""
    <fieldset class={[
      "relative",
      "bg-white/5 dark:bg-black/10",
      "backdrop-blur-xl",
      "border border-white/15 dark:border-white/8",
      "rounded-2xl",
      "p-6 pt-8",
      "shadow-xl shadow-black/5",
      "transition-all duration-300",
      @nested.class
    ]}>
      <legend
        :if={@nested.label}
        class={[
          "absolute -top-3.5 left-4",
          "px-3 py-1",
          "text-xs font-semibold tracking-wide text-gray-600 dark:text-gray-300",
          "bg-white/30 dark:bg-black/40",
          "backdrop-blur-md",
          "border border-white/25 dark:border-white/15",
          "rounded-lg"
        ]}
      >
        {@nested.label}
      </legend>

      <div class="space-y-4">
        <.inputs_for :let={nested_f} field={@form[@nested.name]}>
          <div class={[
            "relative pl-4",
            "border-l-2 border-blue-400/40 dark:border-blue-500/40",
            "rounded-r-xl",
            "bg-white/5 dark:bg-black/10",
            "p-4",
            "transition-all duration-200",
            "hover:border-blue-400/70 dark:hover:border-blue-400/60"
          ]}>
            <div class="space-y-3">
              <%= for f <- @nested.fields do %>
                <%= @theme.render_field(
                  %{form: nested_f, field: f, target: @target, uploads: %{}},
                  @theme_opts
                ) %>
              <% end %>
            </div>

            <button
              :if={@nested.cardinality == :many}
              type="button"
              phx-click="remove_form"
              phx-value-path={nested_f.name}
              phx-target={@target}
              class={[
                "mt-4 inline-flex items-center gap-1.5",
                "text-xs font-medium text-pink-500 dark:text-pink-400",
                "bg-pink-500/10 dark:bg-pink-500/15",
                "backdrop-blur-sm",
                "border border-pink-500/20 dark:border-pink-400/20",
                "rounded-lg px-3 py-1.5",
                "transition-all duration-200",
                "hover:bg-pink-500/20 hover:scale-105",
                "focus:outline-none focus:ring-2 focus:ring-pink-500/40",
                "btn-remove-nested"
              ]}
            >
              <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M6 18L18 6M6 6l12 12"
                />
              </svg>
              {@nested.remove_label}
            </button>
          </div>
        </.inputs_for>
      </div>

      <button
        :if={@nested.cardinality == :many}
        type="button"
        phx-click="add_form"
        phx-value-path={to_string(@nested.name)}
        phx-target={@target}
        class={[
          "mt-4 inline-flex items-center gap-2",
          "text-sm font-medium text-blue-600 dark:text-blue-400",
          "bg-blue-500/10 dark:bg-blue-500/15",
          "backdrop-blur-sm",
          "border border-blue-500/20 dark:border-blue-400/20",
          "rounded-xl px-4 py-2",
          "transition-all duration-200",
          "hover:bg-blue-500/20 hover:scale-[1.02]",
          "focus:outline-none focus:ring-2 focus:ring-blue-500/40",
          "btn-add-nested"
        ]}
      >
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M12 4v16m8-8H4"
          />
        </svg>
        {@nested.add_label}
      </button>
    </fieldset>
    """
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
  # Standard Fields (text, email, password, number, date, datetime-local, etc.)
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
        class="text-xs text-gray-500 dark:text-gray-400 mt-2 transition-all duration-300"
      >
        {@field.hint}
      </p>

      <.field_errors form={@form} field={@field.name} />
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Toggle / Switch for :boolean and :checkbox
  # A pure CSS toggle using Tailwind peer utilities — no JS required.
  # ---------------------------------------------------------------------------

  defp render_toggle(assigns) do
    ~H"""
    <div class={["relative group", @field.wrapper_class]}>
      <div class="flex items-center justify-between">
        <label
          :if={@field.label}
          for={Phoenix.HTML.Form.input_id(@form, @field.name)}
          class="text-sm font-medium text-gray-700 dark:text-gray-200
                 cursor-pointer transition-all duration-300
                 group-hover:text-gray-900 dark:group-hover:text-white"
        >
          {@field.label}
          <span :if={@field.required} class="text-pink-500 ml-1" aria-hidden="true">*</span>
        </label>

        <div class="relative inline-flex shrink-0 items-center ml-4">
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
            class="sr-only peer"
          />
          <label
            for={Phoenix.HTML.Form.input_id(@form, @field.name)}
            class={[
              "relative inline-flex h-7 w-14 cursor-pointer rounded-full",
              "bg-white/20 dark:bg-black/30",
              "backdrop-blur-lg",
              "border-2 border-white/30 dark:border-white/15",
              "transition-all duration-300 ease-out",
              "peer-checked:bg-blue-500/80 dark:peer-checked:bg-blue-600/80",
              "peer-checked:border-blue-400/60",
              "peer-focus-visible:ring-2 peer-focus-visible:ring-blue-500/50 peer-focus-visible:ring-offset-2",
              "hover:scale-105",
              "after:absolute after:left-1 after:top-0.5",
              "after:h-5 after:w-5 after:rounded-full",
              "after:bg-white after:shadow-md",
              "after:transition-all after:duration-300 after:ease-out",
              "peer-checked:after:translate-x-7",
              has_error_class(@form, @field.name)
            ]}
          >
          </label>
        </div>
      </div>

      <p
        :if={@field.hint}
        class="text-xs text-gray-500 dark:text-gray-400 mt-2 transition-all duration-300"
      >
        {@field.hint}
      </p>

      <.field_errors form={@form} field={@field.name} />
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Array Field — multi-select (with options) or free-form textarea
  # ---------------------------------------------------------------------------

  defp render_array_field(assigns) do
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

      <%= if length(@field.options) > 0 do %>
        <select
          id={Phoenix.HTML.Form.input_id(@form, @field.name)}
          name={Phoenix.HTML.Form.input_name(@form, @field.name) <> "[]"}
          multiple
          size="4"
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
            selected={selected_in_array?(
              Phoenix.HTML.Form.input_value(@form, @field.name),
              value
            )}
          >
            {label}
          </option>
        </select>
        <p class="text-xs text-gray-500 dark:text-gray-400 mt-1.5">
          Hold <kbd class="px-1 py-0.5 text-xs bg-white/20 dark:bg-black/30 rounded border border-white/20 dark:border-white/10">Ctrl</kbd>
          or <kbd class="px-1 py-0.5 text-xs bg-white/20 dark:bg-black/30 rounded border border-white/20 dark:border-white/10">⌘</kbd>
          to select multiple items
        </p>
      <% else %>
        <textarea
          id={Phoenix.HTML.Form.input_id(@form, @field.name)}
          name={Phoenix.HTML.Form.input_name(@form, @field.name)}
          placeholder={@field.placeholder || "Enter comma-separated values"}
          rows="3"
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
        <p class="text-xs text-gray-500 dark:text-gray-400 mt-1.5">
          Separate values with commas
        </p>
      <% end %>

      <p :if={@field.hint} class="text-xs text-gray-500 dark:text-gray-400 mt-2">
        {@field.hint}
      </p>

      <.field_errors form={@form} field={@field.name} />
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Input Widget Switcher (used by render_standard_field)
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
          selected={
            to_string(Phoenix.HTML.Form.input_value(@form, @field.name)) == to_string(value)
          }
        >
          {label}
        </option>
      </select>
      <div class="absolute inset-y-0 right-0 flex items-center px-3 pointer-events-none">
        <svg
          class="w-5 h-5 text-gray-500 dark:text-gray-400"
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
        </svg>
      </div>
    </div>
    """
  end

  # Fallback: handles :text_input, :number, :email, :password,
  # :date (→ type="date"), :datetime (→ type="datetime-local"), :url, :tel, etc.
  defp field_input(assigns) do
    assigns = assign(assigns, :input_type, html_input_type(assigns.field.type))

    ~H"""
    <input
      type={@input_type}
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
        @input_type == "password" && "tracking-wide",
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
                  >
                  </div>
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
  # Multiselect Combobox (native multi-select fallback)
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
          selected={
            selected_in_array?(
              Phoenix.HTML.Form.input_value(@form, @field.name),
              value
            )
          }
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
  # Error Display Component
  # ---------------------------------------------------------------------------

  attr(:form, :any, required: true)
  attr(:field, :any, required: true)

  defp field_errors(assigns) do
    assigns =
      assign(assigns, :error_messages, extract_error_messages(assigns.form, assigns.field))

    ~H"""
    <div :if={length(@error_messages) > 0} class="mt-2 space-y-1">
      <%= for msg <- @error_messages do %>
        <p
          class="text-sm text-pink-500 dark:text-pink-400
                 bg-pink-500/10 backdrop-blur-sm
                 px-3 py-2 rounded-lg border border-pink-500/20"
          role="alert"
        >
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

  defp selected_in_array?(nil, _value), do: false

  defp selected_in_array?(values, value) when is_list(values) do
    to_string(value) in Enum.map(values, &to_string/1)
  end

  defp selected_in_array?(values, value) when is_binary(values) do
    to_string(value) in String.split(values, ",", trim: true)
  end

  defp selected_in_array?(_values, _value), do: false

  # Extract human-readable error strings from a Phoenix.HTML.Form field.
  # Phoenix.HTML.FormField.errors is [{String.t(), keyword()}], NOT a keyword list.
  defp extract_error_messages(form, field_name) when is_struct(form, Phoenix.HTML.Form) do
    case form[field_name] do
      nil -> []
      form_field when is_struct(form_field) -> Enum.map(form_field.errors, &elem(&1, 0))
      _ -> []
    end
  end

  defp extract_error_messages(_form, _field_name), do: []

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
  defp html_input_type(:boolean), do: "checkbox"
  defp html_input_type(:number), do: "number"
  defp html_input_type(:email), do: "email"
  defp html_input_type(:password), do: "password"
  # :date and :datetime map to native HTML5 date/time pickers
  defp html_input_type(:date), do: "date"
  defp html_input_type(:datetime), do: "datetime-local"
  defp html_input_type(:url), do: "url"
  defp html_input_type(:tel), do: "tel"
  defp html_input_type(_), do: "text"
end
