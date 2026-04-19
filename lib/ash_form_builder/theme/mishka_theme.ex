defmodule AshFormBuilder.Theme.MishkaTheme do
  @moduledoc """
  Strict MishkaChelekom integration theme for AshFormBuilder.

  This theme strictly utilizes MishkaChelekom components from your deps,
  providing first-class support for many-to-many relationships via the
  searchable `combobox` component.

  ## Setup

  1. Ensure mishka_chelekom is in your deps:

         {:mishka_chelekom, "~> 0.0.8"}

  2. Generate the required components:

         mix mishka.ui.gen.component text_field
         mix mishka.ui.gen.component textarea_field
         mix mishka.ui.gen.component native_select
         mix mishka.ui.gen.component checkbox_field
         mix mishka.ui.gen.component number_field
         mix mishka.ui.gen.component email_field
         mix mishka.ui.gen.component password_field
         mix mishka.ui.gen.component date_time_field
         mix mishka.ui.gen.component url_field
         mix mishka.ui.gen.component combobox

  3. Configure the theme:

         config :ash_form_builder, :theme, AshFormBuilder.Theme.MishkaTheme

  ## Many-to-Many with Combobox

  The `:multiselect_combobox` type renders a searchable multi-select using
  `<MishkaChelekom.Components.Combobox.combobox>`. Pass custom options via `opts`:

      field :specialties do
        type :multiselect_combobox
        opts [
          search_event: "search_specialties",
          debounce: 300,
          placeholder: "Search specialties..."
        ]
      end

  ## Strict Component Usage

  This theme ONLY uses:
  - `MishkaChelekom.Components.Combobox.combobox` for :multiselect_combobox
  - `MishkaChelekom.Components.TextField.text_field` for text/email/password/url/tel
  - `MishkaChelekom.Components.TextareaField.textarea_field` for :textarea
  - `MishkaChelekom.Components.NativeSelect.native_select` for :select
  - `MishkaChelekom.Components.CheckboxField.checkbox_field` for :checkbox
  - `MishkaChelekom.Components.NumberField.number_field` for :number
  - `MishkaChelekom.Components.DateTimeField.date_time_field` for :date/:datetime
  """

  @behaviour AshFormBuilder.Theme

  use Phoenix.Component

  # Strict MishkaChelekom component imports
  # These components must be generated in your host application using:
  #   mix mishka.ui.gen.component <name>
  import MishkaChelekom.Components.Combobox,
    only: [combobox: 1, combobox_input: 1, combobox_options: 1, combobox_option: 1]

  import MishkaChelekom.Components.TextField, only: [text_field: 1]
  import MishkaChelekom.Components.TextareaField, only: [textarea_field: 1]
  import MishkaChelekom.Components.NativeSelect, only: [native_select: 1]
  import MishkaChelekom.Components.CheckboxField, only: [checkbox_field: 1]
  import MishkaChelekom.Components.NumberField, only: [number_field: 1]
  import MishkaChelekom.Components.EmailField, only: [email_field: 1]
  import MishkaChelekom.Components.PasswordField, only: [password_field: 1]
  import MishkaChelekom.Components.DateTimeField, only: [date_time_field: 1]
  import MishkaChelekom.Components.UrlField, only: [url_field: 1]

  # ---------------------------------------------------------------------------
  # Public API - render_field/2
  # ---------------------------------------------------------------------------

  @impl AshFormBuilder.Theme
  def render_field(assigns, opts) do
    assigns = Map.put(assigns, :theme_opts, opts)

    case assigns.field.type do
      :hidden -> render_hidden_field(assigns)
      :multiselect_combobox -> render_multiselect_combobox(assigns)
      :file_upload -> render_file_upload(assigns)
      :textarea -> render_textarea(assigns)
      :select -> render_select(assigns)
      :checkbox -> render_checkbox(assigns)
      :number -> render_number(assigns)
      :email -> render_email(assigns)
      :password -> render_password(assigns)
      :date -> render_date(assigns)
      :datetime -> render_datetime(assigns)
      :url -> render_url(assigns)
      :tel -> render_tel(assigns)
      _ -> render_text_input(assigns)
    end
  end

  @impl AshFormBuilder.Theme
  def render_nested(_assigns) do
    # Return nil to use default nested form rendering
    nil
  end

  # ---------------------------------------------------------------------------
  # File Upload — Phoenix live_file_input with Tailwind/Mishka styling
  # ---------------------------------------------------------------------------

  defp render_file_upload(assigns) do
    upload_config = assigns.uploads[assigns.field.name]
    field_errors = extract_field_errors(assigns.form, assigns.field.name)

    # Get existing file path from form value (for update forms)
    existing_path = get_existing_file_path(assigns.form, assigns.field.name)

    # Determine if field supports multiple files
    upload_opts = Keyword.get(assigns.field.opts, :upload, [])
    max_entries = Keyword.get(upload_opts, :max_entries, 1)
    supports_multiple = max_entries > 1

    assigns =
      assigns
      |> Map.put(:upload_config, upload_config)
      |> Map.put(:field_errors, field_errors)
      |> Map.put(:existing_path, existing_path)
      |> Map.put(:supports_multiple, supports_multiple)

    ~H"""
    <div class={["mb-4", @field.wrapper_class]}>
      <label :if={@field.label} class="block text-sm font-medium mb-1">
        {@field.label}
        <span :if={@field.required} class="text-red-500 ml-1" aria-hidden="true">*</span>
      </label>

      <%!-- Show existing file(s) in update forms --%>
      <div :if={@existing_path} class="mb-4">
        <p class="text-sm font-medium text-gray-700 mb-2">Current File(s):</p>
        
        <%= if is_list(@existing_path) do %>
          <%!-- Multiple existing files --%>
          <div class="grid grid-cols-2 md:grid-cols-3 gap-3">
            <%= for path <- @existing_path do %>
              <.existing_file_preview path={path} field_name={@field.name} form={@form} />
            <% end %>
          </div>
        <% else %>
          <%!-- Single existing file --%>
          <.existing_file_preview path={@existing_path} field_name={@field.name} form={@form} />
        <% end %>
      </div>

      <%!-- Upload new file(s) --%>
      <div :if={@upload_config} class="border-2 border-dashed border-gray-300 rounded-lg p-4">
        <p class="text-sm text-gray-600 mb-2">
          <%= if @existing_path do %>Upload new file to replace<% else %>Select file(s) to upload<% end %>
        </p>
        
        <.live_file_input
          upload={@upload_config}
          class="block w-full text-sm text-gray-500 file:mr-4 file:py-2 file:px-4 file:rounded-md file:border-0 file:text-sm file:font-semibold file:bg-primary/10 file:text-primary hover:file:bg-primary/20"
        />

        <%= for entry <- @upload_config.entries do %>
          <div class="mt-3 flex items-start gap-3">
            <.live_img_preview
              entry={entry}
              class="h-16 w-16 rounded object-cover border border-gray-200"
            />
            <div class="flex-1 min-w-0">
              <p class="text-sm font-medium text-gray-700 truncate">{entry.client_name}</p>
              <div class="mt-1 h-2 w-full rounded-full bg-gray-200">
                <div
                  class="h-2 rounded-full bg-primary transition-all"
                  style={"width: #{entry.progress}%"}
                >
                </div>
              </div>
              <p class="text-xs text-gray-500 mt-1">{entry.progress}%</p>
              <%= for {ref, err} <- @upload_config.errors, ref == entry.ref do %>
                <p class="text-xs text-red-600 mt-1">{upload_error_message(err)}</p>
              <% end %>
            </div>
          </div>
        <% end %>

        <%= for {_ref, err} <- @upload_config.errors do %>
          <p class="text-sm text-red-600 mt-2">{upload_error_message(err)}</p>
        <% end %>
      </div>

      <div :if={is_nil(@upload_config)} class="border rounded-lg p-4 text-sm text-gray-400">
        File upload not configured for this field
      </div>

      <p :if={@field.hint} class="text-xs text-base-content/60 mt-1">{@field.hint}</p>

      <%= for err <- @field_errors do %>
        <p class="text-xs text-red-600 mt-1">{elem(err, 0)}</p>
      <% end %>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Existing File Preview Component
  # ---------------------------------------------------------------------------

  attr(:path, :string, required: true)
  attr(:field_name, :string, required: true)
  attr(:form, :any, required: true)

  defp existing_file_preview(assigns) do
    is_image = image_file?(assigns.path)
    filename = Path.basename(assigns.path)
    delete_flag = get_delete_flag(assigns.form, assigns.field_name)

    assigns =
      assigns
      |> Map.put(:is_image, is_image)
      |> Map.put(:filename, filename)
      |> Map.put(:delete_flag, delete_flag)

    ~H"""
    <div 
      id={"#{@field_name}_preview_container"}
      class={"relative group border rounded-lg p-2 bg-gray-50 hover:bg-gray-100 transition-colors #{if @delete_flag, do: "opacity-50 line-through"}"}
    >
      <%!-- Hidden input to track delete state --%>
      <input
        type="hidden"
        id={"#{@field_name}_delete"}
        name={"#{@field_name}_delete"}
        value={"#{if @delete_flag, do: "true", else: "false"}"}
        phx-hook="FileDeleteToggle"
        data-field={@field_name}
      />

      <div class="flex items-start gap-2">
        <%!-- Image Preview --%>
        <div :if={@is_image} class="relative">
          <img
            src={@path}
            alt={@filename}
            class="h-16 w-16 rounded object-cover border border-gray-200"
            onerror="this.style.display='none'; this.nextElementSibling.style.display='flex'"
          />
          <div class="h-16 w-16 rounded bg-gray-200 border border-gray-300 flex items-center justify-center" style="display: none">
            <svg class="h-8 w-8 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
            </svg>
          </div>
        </div>

        <%!-- File Icon for non-images --%>
        <div :if={not @is_image} class="h-16 w-16 rounded bg-gray-100 border border-gray-200 flex items-center justify-center flex-shrink-0">
          <%= get_file_icon(@path) %>
        </div>

        <%!-- File Info --%>
        <div class="flex-1 min-w-0">
          <p class="text-sm font-medium text-gray-700 truncate" title={@path}>
            {@filename}
          </p>
          <p :if={not @delete_flag} class="text-xs text-gray-500 mt-1">Click delete to remove</p>
        </div>

        <%!-- Delete/Restore Button --%>
        <button
          type="button"
          phx-click="toggle_file_delete"
          phx-value-field={@field_name}
          phx-target={@myself}
          class="absolute top-1 right-1 p-1 rounded-full transition-colors"
          class={"#{if @delete_flag, do: "bg-green-500 hover:bg-green-600 text-white", else: "bg-red-500 hover:bg-red-600 text-white opacity-0 group-hover:opacity-100"}"}
          title={if @delete_flag, do: "Restore this file", else: "Delete this file"}
        >
          <%= if @delete_flag do %>
            <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 10h10a8 8 0 018 8v2M3 10l6 6m-6-6l6-6" />
            </svg>
          <% else %>
            <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
            </svg>
          <% end %>
        </button>
      </div>

      <%!-- Deleted State Indicator --%>
      <div :if={@delete_flag} class="mt-2 text-xs text-red-600 font-medium flex items-center gap-1">
        <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
        </svg>
        Marked for deletion (will be removed on save)
      </div>
    </div>
    """
  end

  defp get_delete_flag(form, field_name) do
    # Check if delete flag is set in form params
    case Phoenix.HTML.Form.input_value(form, "#{field_name}_delete") do
      "true" -> true
      _ -> false
    end
  end

  defp image_file?(path) when is_binary(path) do
    ext = path |> Path.extname() |> String.downcase()
    ext in [".jpg", ".jpeg", ".png", ".gif", ".webp", ".svg", ".bmp"]
  end

  defp image_file?(_), do: false

  defp get_file_icon(path) when is_binary(path) do
    ext = path |> Path.extname() |> String.downcase()

    cond do
      # PDF
      ext == ".pdf" ->
        {:safe,
         "<svg class=\"h-8 w-8 text-red-400\" fill=\"none\" viewBox=\"0 0 24 24\" stroke=\"currentColor\"><path stroke-linecap=\"round\" stroke-linejoin=\"round\" stroke-width=\"2\" d=\"M7 21h10a2 2 0 002-2V9.414a1 1 0 00-.293-.707l-5.414-5.414A1 1 0 0012.586 3H7a2 2 0 00-2 2v14a2 2 0 002 2z\" /></svg>"}

      # Word documents
      ext in [".doc", ".docx"] ->
        {:safe,
         "<svg class=\"h-8 w-8 text-blue-600\" fill=\"none\" viewBox=\"0 0 24 24\" stroke=\"currentColor\"><path stroke-linecap=\"round\" stroke-linejoin=\"round\" stroke-width=\"2\" d=\"M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z\" /></svg>"}

      # Excel spreadsheets
      ext in [".xls", ".xlsx", ".csv"] ->
        {:safe,
         "<svg class=\"h-8 w-8 text-green-600\" fill=\"none\" viewBox=\"0 0 24 24\" stroke=\"currentColor\"><path stroke-linecap=\"round\" stroke-linejoin=\"round\" stroke-width=\"2\" d=\"M9 17v-2m3 2v-4m3 4v-6m2 10H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z\" /></svg>"}

      # Images (shouldn't reach here, but fallback)
      ext in [".jpg", ".jpeg", ".png", ".gif", ".webp", ".svg", ".bmp"] ->
        {:safe,
         "<svg class=\"h-8 w-8 text-purple-400\" fill=\"none\" viewBox=\"0 0 24 24\" stroke=\"currentColor\"><path stroke-linecap=\"round\" stroke-linejoin=\"round\" stroke-width=\"2\" d=\"M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z\" /></svg>"}

      # ZIP/Archive
      ext in [".zip", ".rar", ".7z", ".tar", ".gz"] ->
        {:safe,
         "<svg class=\"h-8 w-8 text-yellow-600\" fill=\"none\" viewBox=\"0 0 24 24\" stroke=\"currentColor\"><path stroke-linecap=\"round\" stroke-linejoin=\"round\" stroke-width=\"2\" d=\"M5 8h14M5 8a2 2 0 110-4h14a2 2 0 110 4M5 8v10a2 2 0 002 2h10a2 2 0 002-2V8m-9 4h4\" /></svg>"}

      # Default document icon
      true ->
        {:safe,
         "<svg class=\"h-8 w-8 text-gray-400\" fill=\"none\" viewBox=\"0 0 24 24\" stroke=\"currentColor\"><path stroke-linecap=\"round\" stroke-linejoin=\"round\" stroke-width=\"2\" d=\"M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z\" /></svg>"}
    end
  end

  defp get_existing_file_path(form, field_name) do
    # Try to get existing value from form
    case Phoenix.HTML.Form.input_value(form, field_name) do
      nil -> nil
      "" -> nil
      value -> value
    end
  end

  defp upload_error_message(:too_large), do: "File is too large"
  defp upload_error_message(:too_many_files), do: "Too many files selected"
  defp upload_error_message(:not_accepted), do: "File type not accepted"
  defp upload_error_message(err), do: "Upload error: #{err}"

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
  # Multiselect Combobox (many_to_many relationships)
  # ---------------------------------------------------------------------------

  defp render_multiselect_combobox(assigns) do
    field = assigns.field
    form = assigns.form
    theme_opts = assigns.theme_opts || []

    # Extract opts from field.opts with sensible defaults
    opts = field.opts || []
    search_event = Keyword.get(opts, :search_event)
    debounce = Keyword.get(opts, :debounce, 300)
    placeholder = Keyword.get(opts, :placeholder, "Search and select...")
    preload_options = Keyword.get(opts, :preload_options, field.options || [])
    creatable? = Keyword.get(opts, :creatable, false)
    create_action = Keyword.get(opts, :create_action, :create)
    create_label = Keyword.get(opts, :create_label, "Create \"#{field.name}\"")

    # Get current selected values from form
    current_values = extract_combobox_values(form, field.name)

    # Get errors from form field
    field_errors = extract_field_errors(form, field.name)

    # Build phx-change attributes if search_event is configured
    change_attrs =
      if search_event do
        [
          phx_change: search_event,
          phx_debounce: debounce,
          phx_target: theme_opts[:target]
        ]
      else
        []
      end

    assigns =
      assigns
      |> Map.put(:placeholder, placeholder)
      |> Map.put(:current_values, current_values)
      |> Map.put(:options, preload_options)
      |> Map.put(:errors, field_errors)
      |> Map.put(:change_attrs, change_attrs)
      |> Map.put(:multiple, true)
      |> Map.put(:creatable?, creatable?)
      |> Map.put(:create_action, create_action)
      |> Map.put(:create_label, create_label)
      |> Map.put(:destination_resource, field.destination_resource)

    ~H"""
    <div class={["mb-4", @field.wrapper_class]}>
      <%!-- Strict MishkaChelekom combobox usage --%>
      <.combobox
        field={@form[@field.name]}
        id={Phoenix.HTML.Form.input_id(@form, @field.name)}
        name={Phoenix.HTML.Form.input_name(@form, @field.name) <> "[]"}
        label={@field.label}
        placeholder={@placeholder}
        multiple={@multiple}
        options={@options}
        value={@current_values}
        required={@field.required}
        errors={@errors}
        color="primary"
        variant="outline"
      >
        <%!-- Custom trigger rendering for selected items --%>
        <:trigger :let={selected}>
          <div class="flex flex-wrap gap-2 p-2">
            <%= for {label, value} <- selected do %>
              <span class="badge badge-primary gap-1">
                {label}
                <button
                  type="button"
                  phx-click="remove_combobox_item"
                  phx-value-field={@field.name}
                  phx-value-item={value}
                  phx-target={@theme_opts[:target]}
                  class="btn btn-xs btn-circle btn-ghost"
                >
                  &times;
                </button>
              </span>
            <% end %>
          </div>
        </:trigger>

        <%!-- Search input with configurable event --%>
        <.combobox_input
          field={@form[@field.name]}
          placeholder={@placeholder}
          {@change_attrs}
        />

        <%!-- Dropdown options --%>
        <.combobox_options>
          <%= for {label, value} <- @options do %>
            <.combobox_option
              value={to_string(value)}
              selected={value in @current_values}
            >
              {label}
            </.combobox_option>
          <% end %>

          <%!-- Creatable button: shown when user types a new value --%>
          <:create_action :if={@creatable?}>
            <button
              type="button"
              phx-click="create_combobox_item"
              phx-value-field={@field.name}
              phx-value-resource={inspect(@destination_resource)}
              phx-value-action={@create_action}
              phx-value-creatable_value={@create_label}
              phx-target={@theme_opts[:target]}
              class="btn btn-sm btn-primary w-full"
            >
              <span class="icon icon-plus"></span>
              {@create_label}
            </button>
          </:create_action>
        </.combobox_options>
      </.combobox>

      <.field_hint hint={@field.hint} />
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Standard Field Types
  # ---------------------------------------------------------------------------

  defp render_textarea(assigns) do
    assigns =
      Map.put(assigns, :field_errors, extract_field_errors(assigns.form, assigns.field.name))

    ~H"""
    <.textarea_field
      field={@form[@field.name]}
      label={@field.label}
      placeholder={@field.placeholder}
      required={@field.required}
      hint={@field.hint}
      errors={@field_errors}
      class={@field.class}
      wrapper_class={@field.wrapper_class}
      color="primary"
      variant="outline"
      rows="4"
    />
    """
  end

  defp render_select(assigns) do
    assigns =
      assigns
      |> Map.put(:field_errors, extract_field_errors(assigns.form, assigns.field.name))
      |> Map.put(:normalized_options, normalize_options(assigns.field.options))

    ~H"""
    <.native_select
      field={@form[@field.name]}
      label={@field.label}
      required={@field.required}
      hint={@field.hint}
      errors={@field_errors}
      class={@field.class}
      wrapper_class={@field.wrapper_class}
      color="primary"
      variant="outline"
      options={@normalized_options}
    />
    """
  end

  defp render_checkbox(assigns) do
    field_errors = extract_field_errors(assigns.form, assigns.field.name)
    assigns = Map.put(assigns, :field_errors, field_errors)

    ~H"""
    <.checkbox_field
      field={@form[@field.name]}
      label={@field.label}
      required={@field.required}
      hint={@field.hint}
      errors={@field_errors}
      class={@field.class}
      wrapper_class={@field.wrapper_class}
      color="primary"
    />
    """
  end

  defp render_number(assigns) do
    field_errors = extract_field_errors(assigns.form, assigns.field.name)
    assigns = Map.put(assigns, :field_errors, field_errors)

    ~H"""
    <.number_field
      field={@form[@field.name]}
      label={@field.label}
      placeholder={@field.placeholder}
      required={@field.required}
      hint={@field.hint}
      errors={@field_errors}
      class={@field.class}
      wrapper_class={@field.wrapper_class}
      color="primary"
      variant="outline"
    />
    """
  end

  defp render_email(assigns) do
    field_errors = extract_field_errors(assigns.form, assigns.field.name)
    assigns = Map.put(assigns, :field_errors, field_errors)

    ~H"""
    <.email_field
      field={@form[@field.name]}
      label={@field.label}
      placeholder={@field.placeholder}
      required={@field.required}
      hint={@field.hint}
      errors={@field_errors}
      class={@field.class}
      wrapper_class={@field.wrapper_class}
      color="primary"
      variant="outline"
    />
    """
  end

  defp render_password(assigns) do
    field_errors = extract_field_errors(assigns.form, assigns.field.name)
    assigns = Map.put(assigns, :field_errors, field_errors)

    ~H"""
    <.password_field
      field={@form[@field.name]}
      label={@field.label}
      placeholder={@field.placeholder}
      required={@field.required}
      hint={@field.hint}
      errors={@field_errors}
      class={@field.class}
      wrapper_class={@field.wrapper_class}
      color="primary"
      variant="outline"
    />
    """
  end

  defp render_date(assigns) do
    field_errors = extract_field_errors(assigns.form, assigns.field.name)
    assigns = Map.put(assigns, :field_errors, field_errors)

    ~H"""
    <.date_time_field
      field={@form[@field.name]}
      label={@field.label}
      type="date"
      placeholder={@field.placeholder}
      required={@field.required}
      hint={@field.hint}
      errors={@field_errors}
      class={@field.class}
      wrapper_class={@field.wrapper_class}
      color="primary"
      variant="outline"
    />
    """
  end

  defp render_datetime(assigns) do
    field_errors = extract_field_errors(assigns.form, assigns.field.name)
    assigns = Map.put(assigns, :field_errors, field_errors)

    ~H"""
    <.date_time_field
      field={@form[@field.name]}
      label={@field.label}
      type="datetime-local"
      placeholder={@field.placeholder}
      required={@field.required}
      hint={@field.hint}
      errors={@field_errors}
      class={@field.class}
      wrapper_class={@field.wrapper_class}
      color="primary"
      variant="outline"
    />
    """
  end

  defp render_url(assigns) do
    field_errors = extract_field_errors(assigns.form, assigns.field.name)
    assigns = Map.put(assigns, :field_errors, field_errors)

    ~H"""
    <.url_field
      field={@form[@field.name]}
      label={@field.label}
      placeholder={@field.placeholder}
      required={@field.required}
      hint={@field.hint}
      errors={@field_errors}
      class={@field.class}
      wrapper_class={@field.wrapper_class}
      color="primary"
      variant="outline"
    />
    """
  end

  defp render_tel(assigns) do
    # MishkaChelekom may not have a specific tel field, use text_field with tel type
    field_errors = extract_field_errors(assigns.form, assigns.field.name)
    assigns = Map.put(assigns, :field_errors, field_errors)

    ~H"""
    <.text_field
      field={@form[@field.name]}
      label={@field.label}
      placeholder={@field.placeholder}
      required={@field.required}
      hint={@field.hint}
      errors={@field_errors}
      class={@field.class}
      wrapper_class={@field.wrapper_class}
      color="primary"
      variant="outline"
      type="tel"
    />
    """
  end

  defp render_text_input(assigns) do
    field_errors = extract_field_errors(assigns.form, assigns.field.name)
    assigns = Map.put(assigns, :field_errors, field_errors)

    ~H"""
    <.text_field
      field={@form[@field.name]}
      label={@field.label}
      placeholder={@field.placeholder}
      required={@field.required}
      hint={@field.hint}
      errors={@field_errors}
      class={@field.class}
      wrapper_class={@field.wrapper_class}
      color="primary"
      variant="outline"
    />
    """
  end

  # ---------------------------------------------------------------------------
  # Shared sub-components
  # ---------------------------------------------------------------------------

  attr(:hint, :string, default: nil)

  defp field_hint(%{hint: nil} = assigns), do: ~H""

  defp field_hint(assigns) do
    ~H"""
    <p class="text-xs text-base-content/60 mt-1">{@hint}</p>
    """
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp extract_field_errors(form, field_name) do
    case form[field_name] do
      nil -> []
      field -> field.errors || []
    end
  end

  defp extract_combobox_values(form, field_name) do
    case Phoenix.HTML.Form.input_value(form, field_name) do
      nil -> []
      values when is_list(values) -> values
      value -> [value]
    end
  end

  defp normalize_options(options) when is_list(options) do
    Enum.map(options, fn
      {label, value} -> {label, value}
      value -> {to_string(value), value}
    end)
  end

  defp normalize_options(_), do: []
end
