defmodule AshFormBuilder.Themes.Shadcn do
  @moduledoc """
  Shadcn/UI-inspired minimal theme for AshFormBuilder.

  ## Aesthetic

  Clean, sharp, and highly accessible design matching the popular shadcn/ui
  component library. Features crisp borders, subtle shadows, and Apple-style
  minimalism without any visual gimmicks.

  ## Configuration

  Add to your `config/config.exs`:

      config :ash_form_builder,
        theme: AshFormBuilder.Themes.Shadcn,
        theme_opts: [
          # Color scheme: :light (default) or :dark
          mode: :light,

          # Border radius: :none, :sm, :md (default), :lg, :full
          radius: :md,

          # Focus ring style: :zinc (default), :blue, :orange, :green
          focus_ring: :zinc
        ]

  ## Visual Characteristics

  * **Solid Backgrounds** - Clean white or zinc backgrounds
  * **Crisp Borders** - Thin, precise borders (border-zinc-200/800)
  * **Subtle Shadows** - Minimal shadow-sm for depth
  * **Sharp Focus** - Clear focus-visible rings with offset
  * **Zero Layout Shift** - No hover animations that affect layout
  * **High Contrast** - Excellent readability and accessibility

  ## Usage

  No additional setup required beyond configuration:

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

  ## Dark Mode

  Configure dark mode for dark backgrounds:

      config :ash_form_builder,
        theme: AshFormBuilder.Themes.Shadcn,
        theme_opts: [mode: :dark]

  ## Accessibility

  This theme prioritizes accessibility:
  * High contrast ratios (WCAG AA compliant)
  * Clear focus indicators
  * Proper ARIA attributes
  * Keyboard navigation support
  * Screen reader friendly

  ## Browser Support

  Works in all modern browsers. Uses standard CSS properties:
  * `:focus-visible` for keyboard focus
  * CSS custom properties for theming
  * Standard flexbox and grid layouts
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
  # Nested Form - themed shadcn/ui rendering
  # ---------------------------------------------------------------------------

  @impl AshFormBuilder.Theme
  def render_nested(assigns) do
    ~H"""
    <div class={[
      "rounded-lg border border-zinc-200 dark:border-zinc-800",
      "bg-zinc-50/50 dark:bg-zinc-900/50",
      "overflow-hidden",
      @nested.class
    ]}>
      <div
        :if={@nested.label}
        class="px-4 py-3 border-b border-zinc-200 dark:border-zinc-800
               bg-white dark:bg-zinc-950"
      >
        <h3 class="text-sm font-semibold text-zinc-950 dark:text-zinc-50">
          {@nested.label}
        </h3>
      </div>

      <div class="p-4 space-y-4">
        <.inputs_for :let={nested_f} field={@form[@nested.name]}>
          <div class={[
            "relative pl-4",
            "border-l-2 border-zinc-200 dark:border-zinc-700",
            "bg-white dark:bg-zinc-950",
            "rounded-r-md",
            "p-4",
            "space-y-3"
          ]}>
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
              class={[
                "inline-flex items-center gap-1.5",
                "text-xs font-medium text-red-600 dark:text-red-400",
                "bg-red-50 dark:bg-red-950/20",
                "border border-red-200 dark:border-red-900",
                "rounded-md px-2.5 py-1.5",
                "transition-colors duration-150",
                "hover:bg-red-100 dark:hover:bg-red-950/40",
                "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-red-500 focus-visible:ring-offset-2",
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

        <button
          :if={@nested.cardinality == :many}
          type="button"
          phx-click="add_form"
          phx-value-path={to_string(@nested.name)}
          phx-target={@target}
          class={[
            "inline-flex items-center gap-2",
            "text-sm font-medium text-zinc-950 dark:text-zinc-50",
            "bg-white dark:bg-zinc-950",
            "border border-zinc-200 dark:border-zinc-800",
            "rounded-md px-3 py-2",
            "shadow-sm",
            "transition-colors duration-150",
            "hover:bg-zinc-50 dark:hover:bg-zinc-900",
            "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-zinc-950 focus-visible:ring-offset-2",
            "dark:focus-visible:ring-zinc-300",
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
      </div>
    </div>
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
    <div class={["space-y-2", @field.wrapper_class]}>
      <label
        :if={@field.label}
        for={Phoenix.HTML.Form.input_id(@form, @field.name)}
        class="text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70
               text-zinc-950 dark:text-zinc-50"
      >
        {@field.label}
        <span :if={@field.required} class="text-red-500 ml-1" aria-hidden="true">*</span>
      </label>

      <.field_input form={@form} field={@field} />

      <p :if={@field.hint} class="text-[0.8rem] text-zinc-500 dark:text-zinc-400">
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
    <div class={["space-y-2", @field.wrapper_class]}>
      <div class="flex items-center justify-between">
        <label
          :if={@field.label}
          for={Phoenix.HTML.Form.input_id(@form, @field.name)}
          class="text-sm font-medium leading-none cursor-pointer select-none
                 text-zinc-950 dark:text-zinc-50
                 peer-disabled:cursor-not-allowed peer-disabled:opacity-70"
        >
          {@field.label}
          <span :if={@field.required} class="text-red-500 ml-1" aria-hidden="true">*</span>
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
              "relative inline-flex h-6 w-11 cursor-pointer rounded-full",
              "bg-zinc-200 dark:bg-zinc-800",
              "border-2 border-transparent",
              "ring-offset-white dark:ring-offset-zinc-950",
              "transition-colors duration-200 ease-in-out",
              "peer-checked:bg-zinc-950 dark:peer-checked:bg-zinc-50",
              "peer-focus-visible:ring-2 peer-focus-visible:ring-zinc-950 peer-focus-visible:ring-offset-2",
              "dark:peer-focus-visible:ring-zinc-300 dark:peer-focus-visible:ring-offset-zinc-950",
              "peer-disabled:cursor-not-allowed peer-disabled:opacity-50",
              "after:absolute after:left-0.5 after:top-0.5",
              "after:h-4 after:w-4 after:rounded-full",
              "after:bg-white dark:after:peer-checked:bg-zinc-950",
              "after:shadow-sm",
              "after:transition-transform after:duration-200",
              "peer-checked:after:translate-x-5",
              has_error_class(@form, @field.name)
            ]}
          >
          </label>
        </div>
      </div>

      <p :if={@field.hint} class="text-[0.8rem] text-zinc-500 dark:text-zinc-400">
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
    <div class={["space-y-2", @field.wrapper_class]}>
      <label
        :if={@field.label}
        for={Phoenix.HTML.Form.input_id(@form, @field.name)}
        class="text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70
               text-zinc-950 dark:text-zinc-50"
      >
        {@field.label}
        <span :if={@field.required} class="text-red-500 ml-1" aria-hidden="true">*</span>
      </label>

      <%= if length(@field.options) > 0 do %>
        <select
          id={Phoenix.HTML.Form.input_id(@form, @field.name)}
          name={Phoenix.HTML.Form.input_name(@form, @field.name) <> "[]"}
          multiple
          size="4"
          class={[
            "flex w-full rounded-md border border-zinc-200 dark:border-zinc-800",
            "bg-white dark:bg-zinc-950",
            "px-3 py-2 text-sm ring-offset-white dark:ring-offset-zinc-950",
            "text-zinc-950 dark:text-zinc-50",
            "focus-visible:outline-none",
            "focus-visible:ring-2 focus-visible:ring-zinc-950 focus-visible:ring-offset-2",
            "dark:focus-visible:ring-zinc-300 dark:focus-visible:ring-offset-zinc-950",
            "disabled:cursor-not-allowed disabled:opacity-50",
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
        <p class="text-[0.75rem] text-zinc-500 dark:text-zinc-400">
          Hold <kbd class="px-1 py-px text-xs bg-zinc-100 dark:bg-zinc-800 rounded border border-zinc-200 dark:border-zinc-700 font-mono">Ctrl</kbd>
          or <kbd class="px-1 py-px text-xs bg-zinc-100 dark:bg-zinc-800 rounded border border-zinc-200 dark:border-zinc-700 font-mono">⌘</kbd>
          to select multiple
        </p>
      <% else %>
        <textarea
          id={Phoenix.HTML.Form.input_id(@form, @field.name)}
          name={Phoenix.HTML.Form.input_name(@form, @field.name)}
          placeholder={@field.placeholder || "Enter comma-separated values"}
          rows="3"
          class={[
            "flex w-full rounded-md border border-zinc-200 dark:border-zinc-800",
            "bg-white dark:bg-zinc-950",
            "px-3 py-2 text-sm ring-offset-white dark:ring-offset-zinc-950",
            "text-zinc-950 dark:text-zinc-50",
            "placeholder:text-zinc-500 dark:placeholder:text-zinc-400",
            "focus-visible:outline-none",
            "focus-visible:ring-2 focus-visible:ring-zinc-950 focus-visible:ring-offset-2",
            "dark:focus-visible:ring-zinc-300 dark:focus-visible:ring-offset-zinc-950",
            "disabled:cursor-not-allowed disabled:opacity-50",
            has_error_class(@form, @field.name),
            @field.class
          ]}
        ><%= Phoenix.HTML.Form.input_value(@form, @field.name) %></textarea>
        <p class="text-[0.75rem] text-zinc-500 dark:text-zinc-400">
          Separate values with commas
        </p>
      <% end %>

      <p :if={@field.hint} class="text-[0.8rem] text-zinc-500 dark:text-zinc-400">
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
        "flex w-full rounded-md border border-zinc-200 dark:border-zinc-800",
        "bg-white dark:bg-zinc-950",
        "px-3 py-2 text-sm ring-offset-white dark:ring-offset-zinc-950",
        "text-zinc-950 dark:text-zinc-50",
        "placeholder:text-zinc-500 dark:placeholder:text-zinc-400",
        "focus-visible:outline-none",
        "focus-visible:ring-2 focus-visible:ring-zinc-950 focus-visible:ring-offset-2",
        "dark:focus-visible:ring-zinc-300 dark:focus-visible:ring-offset-zinc-950",
        "disabled:cursor-not-allowed disabled:opacity-50",
        "font-mono",
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
          "flex w-full items-center justify-between rounded-md border border-zinc-200 dark:border-zinc-800",
          "bg-white dark:bg-zinc-950",
          "px-3 py-2 pr-8 text-sm ring-offset-white dark:ring-offset-zinc-950",
          "text-zinc-950 dark:text-zinc-50",
          "focus-visible:outline-none",
          "focus-visible:ring-2 focus-visible:ring-zinc-950 focus-visible:ring-offset-2",
          "dark:focus-visible:ring-zinc-300 dark:focus-visible:ring-offset-zinc-950",
          "disabled:cursor-not-allowed disabled:opacity-50",
          "appearance-none cursor-pointer",
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
      <div class="absolute inset-y-0 right-0 flex items-center px-2.5 pointer-events-none">
        <svg
          class="w-4 h-4 text-zinc-500 dark:text-zinc-400"
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
        "flex w-full rounded-md border border-zinc-200 dark:border-zinc-800",
        "bg-white dark:bg-zinc-950",
        "px-3 py-2 text-sm ring-offset-white dark:ring-offset-zinc-950",
        "text-zinc-950 dark:text-zinc-50",
        "placeholder:text-zinc-500 dark:placeholder:text-zinc-400",
        "focus-visible:outline-none",
        "focus-visible:ring-2 focus-visible:ring-zinc-950 focus-visible:ring-offset-2",
        "dark:focus-visible:ring-zinc-300 dark:focus-visible:ring-offset-zinc-950",
        "disabled:cursor-not-allowed disabled:opacity-50",
        "file:border-0 file:bg-transparent file:text-sm file:font-medium",
        "file:text-zinc-950 dark:file:text-zinc-50",
        @input_type == "password" && "tracking-normal",
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
    <div class={["space-y-2", @field.wrapper_class]}>
      <label
        :if={@field.label}
        class="text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70
               text-zinc-950 dark:text-zinc-50"
      >
        {@field.label}
        <span :if={@field.required} class="text-red-500 ml-1" aria-hidden="true">*</span>
      </label>

      <div
        :if={@uploads[@field.name]}
        class={[
          "flex flex-col items-center justify-center w-full",
          "rounded-lg border-2 border-dashed border-zinc-200 dark:border-zinc-800",
          "bg-white dark:bg-zinc-950",
          "p-8",
          "transition-colors duration-200 ease-in-out",
          "hover:border-zinc-400 dark:hover:border-zinc-600",
          "hover:bg-zinc-50 dark:hover:bg-zinc-900"
        ]}
      >
        <.live_file_input
          upload={@uploads[@field.name]}
          class="block w-full text-sm text-zinc-500 dark:text-zinc-400
                 file:mr-4 file:py-2 file:px-4
                 file:rounded-md file:border-0
                 file:text-sm file:font-medium
                 file:bg-zinc-100 dark:file:bg-zinc-800
                 file:text-zinc-950 dark:file:text-zinc-50
                 hover:file:bg-zinc-200 dark:hover:file:bg-zinc-700
                 cursor-pointer"
        />
        <p class="mt-2 text-xs text-zinc-500 dark:text-zinc-400">
          Click to upload or drag and drop
        </p>

        <div :if={length(@uploads[@field.name].entries) > 0} class="w-full mt-4 space-y-3">
          <%= for entry <- @uploads[@field.name].entries do %>
            <div class={[
              "flex items-center gap-3 p-3",
              "rounded-md border border-zinc-200 dark:border-zinc-800",
              "bg-zinc-50 dark:bg-zinc-900"
            ]}>
              <.live_img_preview
                entry={entry}
                class="h-12 w-12 rounded object-cover border border-zinc-200 dark:border-zinc-800"
              />
              <div class="flex-1 min-w-0">
                <p class="text-sm font-medium text-zinc-950 dark:text-zinc-50 truncate">
                  {entry.client_name}
                </p>
                <div class="mt-1.5 h-1.5 w-full rounded-full bg-zinc-200 dark:bg-zinc-800">
                  <div
                    class="h-full rounded-full bg-zinc-950 dark:bg-zinc-50 transition-all duration-300"
                    style={"width: #{entry.progress}%"}
                  >
                  </div>
                </div>
                <p class="text-xs text-zinc-500 dark:text-zinc-400 mt-1">{entry.progress}%</p>
              </div>
            </div>
          <% end %>
        </div>

        <div :if={length(@uploads[@field.name].errors) > 0} class="w-full mt-4 space-y-2">
          <%= for {_ref, err} <- @uploads[@field.name].errors do %>
            <p class="text-sm text-red-500 dark:text-red-400
                      bg-red-50 dark:bg-red-950/20
                      px-3 py-2 rounded-md border border-red-200 dark:border-red-900">
              {upload_error_message(err)}
            </p>
          <% end %>
        </div>
      </div>

      <p :if={@field.hint} class="text-[0.8rem] text-zinc-500 dark:text-zinc-400">
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
    <div class={["space-y-2", @field.wrapper_class]}>
      <label
        :if={@field.label}
        for={Phoenix.HTML.Form.input_id(@form, @field.name)}
        class="text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70
               text-zinc-950 dark:text-zinc-50"
      >
        {@field.label}
        <span :if={@field.required} class="text-red-500 ml-1" aria-hidden="true">*</span>
      </label>

      <select
        id={Phoenix.HTML.Form.input_id(@form, @field.name)}
        name={Phoenix.HTML.Form.input_name(@form, @field.name) <> "[]"}
        multiple
        size="5"
        class={[
          "flex w-full rounded-md border border-zinc-200 dark:border-zinc-800",
          "bg-white dark:bg-zinc-950",
          "px-3 py-2 text-sm ring-offset-white dark:ring-offset-zinc-950",
          "text-zinc-950 dark:text-zinc-50",
          "focus-visible:outline-none",
          "focus-visible:ring-2 focus-visible:ring-zinc-950 focus-visible:ring-offset-2",
          "dark:focus-visible:ring-zinc-300 dark:focus-visible:ring-offset-zinc-950",
          "disabled:cursor-not-allowed disabled:opacity-50",
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

      <p :if={@field.hint} class="text-[0.8rem] text-zinc-500 dark:text-zinc-400">
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
    <div :if={length(@error_messages) > 0} class="space-y-1">
      <%= for msg <- @error_messages do %>
        <p class="text-sm font-medium text-red-500 dark:text-red-400" role="alert">
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
      _ -> "border-red-500 focus-visible:ring-red-500"
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
