# =============================================================================
# AshFormBuilder - Complete Integration Guide
# =============================================================================
#
# This comprehensive guide demonstrates how to integrate AshFormBuilder into
# your Phoenix + Ash application with the "Invisible UI" philosophy:
#
#   "The developer defines the business logic in Ash, and the UI is a side effect."
#
# ## Table of Contents
#
# 1. Installation & Setup
# 2. Resource Definition with Form DSL
# 3. Domain Configuration (Code Interfaces)
# 4. Phoenix LiveView Integration
# 5. Creatable Combobox (Create on-the-fly)
# 6. Theme Customization & Adapters
# 7. Search Handling for Combobox
# 8. Areas of Enhancement
#
# =============================================================================

# =============================================================================
# 1. INSTALLATION & SETUP
# =============================================================================

# ─────────────────────────────────────────────────────────────────────────────
# 1.1 Add Dependencies (mix.exs)
# ─────────────────────────────────────────────────────────────────────────────

# defp deps do
#   [
#     {:ash, "~> 3.0"},
#     {:ash_phoenix, "~> 2.0"},
#     {:phoenix_live_view, "~> 1.0"},
#     {:phoenix, "~> 1.7"},
#     {:ash_form_builder, path: "../ash_form_builder"},  # Or from hex when published
#     
#     # Optional: UI Component Libraries
#     {:mishka_chelekom, "~> 0.0.8"},  # For MishkaTheme
#     {:daisy_ui, "~> 4.0"}             # For Tailwind components (optional)
#   ]
# end

# ─────────────────────────────────────────────────────────────────────────────
# 1.2 Configure Theme (config/config.exs)
# ─────────────────────────────────────────────────────────────────────────────

# config :ash_form_builder, :theme, AshFormBuilder.Theme.MishkaTheme
# # or
# config :ash_form_builder, :theme, AshFormBuilder.Themes.Default
# # or your custom theme
# config :ash_form_builder, :theme, MyAppWeb.CustomTheme

# ─────────────────────────────────────────────────────────────────────────────
# 1.3 Add Extension to Resource
# ─────────────────────────────────────────────────────────────────────────────

# In your Ash Resource, add the extension:
#
# use Ash.Resource,
#   domain: MyApp.Healthcare,
#   extensions: [AshFormBuilder]  # ← Add this

# =============================================================================
# 2. RESOURCE DEFINITION WITH FORM DSL
# =============================================================================

defmodule MyApp.Healthcare.Clinic do
  @moduledoc """
  Clinic resource demonstrating AshFormBuilder with many-to-many relationships.
  
  ## Form Auto-Inference
  
  Fields are automatically inferred from the action's `accept` list:
  
  | Ash Type          | UI Type                 |
  |-------------------|-------------------------|
  | `:string`         | `:text_input`           |
  | `:integer`        | `:number`               |
  | `:boolean`        | `:checkbox`             |
  | `:date`           | `:date`                 |
  | `:datetime`       | `:datetime`             |
  | `:enum`           | `:select`               |
  | `many_to_many`    | `:multiselect_combobox` |
  """

  use Ash.Resource,
    domain: MyApp.Healthcare,
    extensions: [AshFormBuilder]

  # ───────────────────────────────────────────────────────────────────────────
  # Attributes
  # ───────────────────────────────────────────────────────────────────────────

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      allow_nil? false
      description "The clinic's official name"
    end

    attribute :address, :string do
      allow_nil? false
    end

    attribute :phone, :string do
      constraints match: ~r/^\+?[\d\s-]+$/
    end

    attribute :email, :string
    attribute :website, :string
    attribute :is_active, :boolean, default: true

    timestamps()
  end

  # ───────────────────────────────────────────────────────────────────────────
  # Relationships
  # ───────────────────────────────────────────────────────────────────────────

  relationships do
    # Many-to-many: Auto-rendered as :multiselect_combobox
    many_to_many :specialties, MyApp.Healthcare.Specialty do
      through MyApp.Healthcare.ClinicSpecialty
      source_attribute_on_join_resource :clinic_id
      destination_attribute_on_join_resource :specialty_id
    end

    # Many-to-many with creatable support (create new items on-the-fly)
    many_to_many :tags, MyApp.Healthcare.Tag do
      through MyApp.Healthcare.ClinicTag
      source_attribute_on_join_resource :clinic_id
      destination_attribute_on_join_resource :tag_id
    end
  end

  # ───────────────────────────────────────────────────────────────────────────
  # Actions
  # ───────────────────────────────────────────────────────────────────────────

  actions do
    defaults [:create, :read, :update, :destroy]

    create :create do
      accept [:name, :address, :phone, :email, :website, :is_active]
      # Manage relationships separately
      manage_relationship :specialties, :specialties, type: :append_and_remove
      manage_relationship :tags, :tags, type: :append_and_remove
    end

    update :update do
      accept [:name, :address, :phone, :email, :website, :is_active]
      manage_relationship :specialties, :specialties, type: :append_and_remove
      manage_relationship :tags, :tags, type: :append_and_remove
    end
  end

  # ───────────────────────────────────────────────────────────────────────────
  # Validations & Policies
  # ───────────────────────────────────────────────────────────────────────────

  validations do
    validate present([:name, :address])
    validate string_length(:name, min: 3, max: 100)
  end

  policies do
    policy action_type(:create) do
      authorize_if actor_present()
    end

    policy action_type(:update) do
      authorize_if actor_present()
    end
  end

  # ===========================================================================
  # ASH FORM BUILDER DSL - Declarative Form Configuration
  # ===========================================================================
  #
  # The `form` block defines how your form should render. Fields not declared
  # here are auto-inferred from the action's `accept` list.
  #
  # ===========================================================================

  form do
    # Required: Target action
    action :create

    # Optional: Customize submit button
    submit_label "Create Clinic"

    # Optional: CSS class for fields wrapper
    wrapper_class "space-y-6"

    # Optional: HTML id for the <form> element
    # form_id "clinic-create-form"

    # ────────────────────────────────────────────────────────────────────────
    # Field Overrides
    # ────────────────────────────────────────────────────────────────────────
    #
    # Declare fields to override auto-inferred settings or add customization.
    # Fields not declared here are still rendered with defaults.
    # ────────────────────────────────────────────────────────────────────────

    field :name do
      label "Clinic Name"
      placeholder "e.g., Downtown Medical Center"
      required true
      # Optional: CSS classes
      # class "input-lg"
      # wrapper_class "mb-6"
    end

    field :address do
      label "Street Address"
      type :textarea  # Override inferred :text_input
      placeholder "Full address including city and zip"
      # Additional textarea options
      # rows 4
      required true
    end

    field :phone do
      label "Contact Phone"
      placeholder "+1 555-123-4567"
      # type :tel  # Could override to :tel for mobile keyboards
    end

    field :email do
      label "Email Address"
      type :email  # Override to email input type
      placeholder "contact@clinic.com"
    end

    field :website do
      label "Website URL"
      type :url
      placeholder "https://www.clinic.com"
    end

    field :is_active do
      label "Clinic Active"
      type :checkbox
      hint "Uncheck to mark as temporarily closed"
    end

    # ────────────────────────────────────────────────────────────────────────
    # Many-to-Many: Searchable Combobox (NON-CREATABLE)
    # ────────────────────────────────────────────────────────────────────────
    #
    # Use when users should only select from existing records.
    # ────────────────────────────────────────────────────────────────────────

    field :specialties do
      type :multiselect_combobox
      label "Medical Specialties"
      placeholder "Search specialties..."
      required false

      opts [
        # LiveView search event handler
        search_event: "search_specialties",

        # Debounce delay in milliseconds
        debounce: 300,

        # Resource field mappings
        label_key: :name,  # Field to display in dropdown
        value_key: :id,    # Field to use as value

        # Optional: Preload options (for small datasets)
        # preload_options: [{"Cardiology", "uuid-1"}, {"Pediatrics", "uuid-2"}]

        # Hint text
        hint: "Search and select all applicable specialties"
      ]
    end

    # ────────────────────────────────────────────────────────────────────────
    # Many-to-Many: CREATABLE Combobox ⭐ NEW FEATURE
    # ────────────────────────────────────────────────────────────────────────
    #
    # Use when users should be able to create new items on-the-fly.
    # Example: Tags, categories, or labels that don't exist yet.
    # ────────────────────────────────────────────────────────────────────────

    field :tags do
      type :multiselect_combobox
      label "Tags"
      placeholder "Search or create tags..."
      required false

      opts [
        # ★ Enable creatable functionality
        creatable: true,

        # Action to call on destination resource (default: :create)
        create_action: :create,

        # Label template for create button
        # The empty quotes "" will be replaced with user's input
        create_label: "Create \"\"",

        # LiveView search event handler
        search_event: "search_tags",

        # Debounce delay in milliseconds
        debounce: 300,

        # Resource field mappings
        label_key: :name,
        value_key: :id,

        # Hint text
        hint: "Type to search existing tags or create a new one"
      ]
    end

    # ────────────────────────────────────────────────────────────────────────
    # Nested Forms (has_many relationships)
    # ────────────────────────────────────────────────────────────────────────
    #
    # For managing child records inline (e.g., clinic departments).
    # ────────────────────────────────────────────────────────────────────────

    # nested :departments do
    #   label "Departments"
    #   cardinality :many  # or :one
    #   add_label "Add Department"
    #   remove_label "Remove"
    #   create_action :create
    #   update_action :update
    #
    #   # Nested fields
    #   field :name do
    #     label "Department Name"
    #     required true
    #   end
    #
    #   field :budget do
    #     label "Annual Budget"
    #     type :number
    #   end
    # end
  end

  # ===========================================================================
  # UPDATE FORM - Separate configuration for update action
  # ===========================================================================
  #
  # You can define multiple `form` blocks in the same resource.
  # Each targets a different action (create, update, destroy, etc.)
  #
  # Update forms automatically:
  # - Preload many_to_many relationships to show existing selections
  # - Populate all fields with current record values
  # ===========================================================================

  form do
    # Target the update action
    action :update

    # Customize submit button for update
    submit_label "Save Changes"

    # Optional: Different wrapper class for update forms
    # wrapper_class "space-y-6 update-form"

    # Field customizations specific to update forms
    field :name do
      label "Clinic Name"
      placeholder "e.g., Downtown Medical Center"
      required true
      # Update-specific hint
      hint "Changing the name will require re-verification"
    end

    field :address do
      label "Street Address"
      type :textarea
      placeholder "Full address including city and zip"
      required true
    end

    field :phone do
      label "Contact Phone"
      placeholder "+1 555-123-4567"
    end

    field :email do
      label "Email Address"
      type :email
      placeholder "contact@clinic.com"
    end

    field :website do
      label "Website URL"
      type :url
      placeholder "https://www.clinic.com"
    end

    field :is_active do
      label "Clinic Active"
      type :checkbox
      hint "Uncheck to mark as temporarily closed"
    end

    # Many-to-Many: Searchable Combobox
    # In update forms, existing selections are automatically preloaded
    field :specialties do
      type :multiselect_combobox
      label "Medical Specialties"
      placeholder "Search specialties..."
      required false

      opts [
        search_event: "search_specialties",
        debounce: 300,
        label_key: :name,
        value_key: :id,
        hint: "Search and select all applicable specialties"
      ]
    end

    # Many-to-Many: Creatable Combobox
    field :tags do
      type :multiselect_combobox
      label "Tags"
      placeholder "Search or create tags..."
      required false

      opts [
        creatable: true,
        create_action: :create,
        create_label: "Create \"\"",
        search_event: "search_tags",
        debounce: 300,
        label_key: :name,
        value_key: :id,
        hint: "Type to search existing tags or create a new one"
      ]
    end
  end
end

# =============================================================================
# 3. SUPPORTING RESOURCES
# =============================================================================

defmodule MyApp.Healthcare.Specialty do
  @moduledoc "Medical specialty (e.g., Cardiology, Pediatrics)"

  use Ash.Resource,
    domain: MyApp.Healthcare,
    data_layer: Ash.DataLayer.Ets  # Replace with your data layer

  attributes do
    uuid_primary_key :id
    attribute :name, :string, allow_nil?: false
    attribute :code, :string, allow_nil?: false
    attribute :description, :string
  end

  actions do
    defaults [:read, :create]
  end
end

defmodule MyApp.Healthcare.Tag do
  @moduledoc "Tag for categorization (creatable on-the-fly)"

  use Ash.Resource,
    domain: MyApp.Healthcare,
    data_layer: Ash.DataLayer.Ets

  attributes do
    uuid_primary_key :id
    attribute :name, :string, allow_nil?: false
    attribute :color, :string, default: "gray"
  end

  actions do
    defaults [:read, :create]
  end
end

# Join resources for many-to-many relationships
defmodule MyApp.Healthcare.ClinicSpecialty do
  use Ash.Resource,
    domain: MyApp.Healthcare

  attributes do
    uuid_primary_key :id
    attribute :clinic_id, :uuid, allow_nil?: false
    attribute :specialty_id, :uuid, allow_nil?: false
  end

  relationships do
    belongs_to :clinic, MyApp.Healthcare.Clinic
    belongs_to :specialty, MyApp.Healthcare.Specialty
  end
end

defmodule MyApp.Healthcare.ClinicTag do
  use Ash.Resource,
    domain: MyApp.Healthcare

  attributes do
    uuid_primary_key :id
    attribute :clinic_id, :uuid, allow_nil?: false
    attribute :tag_id, :uuid, allow_nil?: false
  end

  relationships do
    belongs_to :clinic, MyApp.Healthcare.Clinic
    belongs_to :tag, MyApp.Healthcare.Tag
  end
end

# =============================================================================
# 4. DOMAIN CONFIGURATION (CODE INTERFACES)
# =============================================================================
#
# Domain Code Interfaces generate clean helper functions that integrate
# seamlessly with AshFormBuilder. This is the recommended pattern.
#
# ─────────────────────────────────────────────────────────────────────────────
# Why Use Code Interfaces?
# ─────────────────────────────────────────────────────────────────────────────
#
# • Zero boilerplate - No manual AshPhoenix.Form calls
# • Type-safe - Generated functions with proper specs
# • Policy-aware - Automatically includes actor context
# • Consistent - Standardized form creation across your app
#
# ─────────────────────────────────────────────────────────────────────────────

defmodule MyApp.Healthcare do
  @moduledoc """
  Healthcare domain with Code Interfaces for form generation.
  """

  use Ash.Domain

  resources do
    # ────────────────────────────────────────────────────────────────────────
    # Clinic Resource with Form Code Interfaces
    # ────────────────────────────────────────────────────────────────────────

    resource MyApp.Healthcare.Clinic do
      # Standard CRUD operations
      define :list_clinics, action: :read
      define :get_clinic, action: :read, get_by: [:id]

      # ★ Form Code Interfaces - Auto-generates helper functions
      #
      # Generates:
      #   - MyApp.Healthcare.Clinic.Form.for_create/1
      #   - MyApp.Healthcare.Clinic.Form.for_update/2
      #
      define :form_to_create_clinic, action: :create
      define :form_to_update_clinic, action: :update
    end

    # ────────────────────────────────────────────────────────────────────────
    # Supporting Resources
    # ────────────────────────────────────────────────────────────────────────

    resource MyApp.Healthcare.Specialty do
      define :list_specialties, action: :read
      define :search_specialties, action: :read
    end

    resource MyApp.Healthcare.Tag do
      define :list_tags, action: :read
      define :search_tags, action: :read
    end
  end
end

# =============================================================================
# 5. PHOENIX LIVEVIEW INTEGRATION
# =============================================================================
#
# The LiveView is remarkably simple thanks to Domain Code Interfaces.
# No manual AshPhoenix.Form setup required!
#
# ─────────────────────────────────────────────────────────────────────────────

defmodule MyAppWeb.ClinicLive.Form do
  @moduledoc """
  LiveView for creating/editing Clinics.
  
  ## Key Features Demonstrated
  
  - Zero manual AshPhoenix.Form calls
  - Domain Code Interface usage
  - MishkaTheme with searchable combobox
  - Creatable combobox for tags
  - Automatic policy enforcement
  """

  use MyAppWeb, :live_view

  alias MyApp.Healthcare

  # ───────────────────────────────────────────────────────────────────────────
  # MOUNT - Form Creation via Domain Code Interface
  # ───────────────────────────────────────────────────────────────────────────

  @impl true
  def mount(%{"id" => id} = _params, _session, socket) do
    # EDIT MODE: Update existing clinic
    #
    # Note: for_update/2 automatically preloads required many_to_many relationships
    # so the combobox displays current selections. Manual preloading shown here
    # is optional but useful if you need the loaded data for other purposes.
    #
    clinic = Healthcare.get_clinic!(id, load: [:specialties, :tags], actor: socket.assigns.current_user)

    # for_update/2 auto-preloads required relationships based on form configuration
    form = Healthcare.Clinic.Form.for_update(clinic, actor: socket.assigns.current_user)

    {:ok,
     socket
     |> assign(:page_title, "Edit Clinic")
     |> assign(:form, form)
     |> assign(:mode, :edit)
     |> assign(:specialty_options, load_options(clinic.specialties))
     |> assign(:tag_options, load_options(clinic.tags))}
  end

  def mount(_params, _session, socket) do
    # CREATE MODE: New clinic
    #
    # The Form.for_create/1 helper is generated by the Domain Code Interface
    # and configured via the form DSL block in the resource.
    #
    form = Healthcare.Clinic.Form.for_create(actor: socket.assigns.current_user)

    {:ok,
     socket
     |> assign(:page_title, "New Clinic")
     |> assign(:form, form)
     |> assign(:mode, :create)
     |> assign(:specialty_options, [])
     |> assign(:tag_options, [])}
  end

  # ───────────────────────────────────────────────────────────────────────────
  # RENDER - Using FormComponent
  # ───────────────────────────────────────────────────────────────────────────

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-3xl mx-auto px-4 py-8">
      <h1 class="text-3xl font-bold mb-6 text-base-content"><%= @page_title %></h1>

      <div class="card bg-base-100 shadow-xl">
        <div class="card-body">
          <%!--
            The FormComponent:
            - Uses the configured theme (MishkaTheme)
            - Renders all fields from the form DSL
            - Handles validation errors automatically
            - Manages nested forms
          --%>
          <.live_component
            module={AshFormBuilder.FormComponent}
            id="clinic-form"
            resource={MyApp.Healthcare.Clinic}
            form={@form}
          />
        </div>
      </div>
    </div>
    """
  end

  # ───────────────────────────────────────────────────────────────────────────
  # SEARCH HANDLERS - For Combobox Many-to-Many
  # ───────────────────────────────────────────────────────────────────────────
  #
  # These handlers respond to combobox search events and push
  # updated options back to the client via LiveView events.
  # ───────────────────────────────────────────────────────────────────────────

  @impl true
  def handle_event("search_specialties", %{"query" => query}, socket) do
    specialties =
      MyApp.Healthcare.Specialty
      |> Ash.Query.filter(contains(name: ^query))
      |> Healthcare.read!(actor: socket.assigns.current_user)

    options = Enum.map(specialties, &{&1.name, &1.id})

    {:noreply, push_event(socket, "update_combobox_options", %{
      field: "specialties",
      options: options
    })}
  end

  @impl true
  def handle_event("search_tags", %{"query" => query}, socket) do
    # For creatable combobox, search existing tags
    # Users can still create new ones via the create button
    tags =
      MyApp.Healthcare.Tag
      |> Ash.Query.filter(contains(name: ^query))
      |> Healthcare.read!(actor: socket.assigns.current_user)

    options = Enum.map(tags, &{&1.name, &1.id})

    {:noreply, push_event(socket, "update_combobox_options", %{
      field: "tags",
      options: options
    })}
  end

  # ───────────────────────────────────────────────────────────────────────────
  # SUCCESS HANDLER - Form Submission
  # ───────────────────────────────────────────────────────────────────────────

  @impl true
  def handle_info({:form_submitted, MyApp.Healthcare.Clinic, clinic}, socket) do
    message = case socket.assigns.mode do
      :create -> "Clinic created successfully!"
      :update -> "Clinic updated successfully!"
    end

    {:noreply,
     socket
     |> put_flash(:info, message)
     |> push_navigate(to: ~p"/clinics/#{clinic.id}")}
  end

  # ───────────────────────────────────────────────────────────────────────────
  # PRIVATE HELPERS
  # ───────────────────────────────────────────────────────────────────────────

  defp load_options(records) do
    Enum.map(records, &{&1.name, &1.id})
  end
end

# =============================================================================
# 6. THEME CUSTOMIZATION & ADAPTERS
# =============================================================================
#
# AshFormBuilder supports theming via the `AshFormBuilder.Theme` behaviour.
# You can use built-in themes or create custom adapters.
#
# ─────────────────────────────────────────────────────────────────────────────
# 6.1 Built-in Themes
# ─────────────────────────────────────────────────────────────────────────────
#
# • AshFormBuilder.Themes.Default - Semantic HTML with minimal styling
# • AshFormBuilder.Theme.MishkaTheme - MishkaChelekom component integration
#
# ─────────────────────────────────────────────────────────────────────────────
# 6.2 Creating a Custom Theme
# ─────────────────────────────────────────────────────────────────────────────

defmodule MyAppWeb.CustomTheme do
  @moduledoc """
  Custom theme example using Tailwind CSS directly.
  
  To use:
  1. Create this module in your app
  2. Implement render_field/2 for each field type
  3. Configure: config :ash_form_builder, :theme, MyAppWeb.CustomTheme
  """

  @behaviour AshFormBuilder.Theme
  use Phoenix.Component

  @impl AshFormBuilder.Theme
  def render_field(assigns, opts) do
    # Add your custom assigns
    assigns = Map.put(assigns, :custom_opts, opts)

    case assigns.field.type do
      :text_input -> render_text_input(assigns)
      :textarea -> render_textarea(assigns)
      :select -> render_select(assigns)
      :multiselect_combobox -> render_combobox(assigns)
      :checkbox -> render_checkbox(assigns)
      :number -> render_number(assigns)
      :email -> render_email(assigns)
      :password -> render_password(assigns)
      :date -> render_date(assigns)
      :datetime -> render_datetime(assigns)
      :url -> render_url(assigns)
      :tel -> render_tel(assigns)
      :hidden -> render_hidden(assigns)
      _ -> render_text_input(assigns)
    end
  end

  @impl AshFormBuilder.Theme
  def render_nested(_assigns) do
    # Return nil to use default nested form rendering
    nil
  end

  # ───────────────────────────────────────────────────────────────────────────
  # Example: Custom Text Input with Tailwind
  # ───────────────────────────────────────────────────────────────────────────

  defp render_text_input(assigns) do
    ~H"""
    <div class={["mb-4", @field.wrapper_class]}>
      <label :if={@field.label} class="block text-sm font-medium text-gray-700 mb-1">
        {@field.label}
        <span :if={@field.required} class="text-red-500 ml-1">*</span>
      </label>
      <input
        type="text"
        id={Phoenix.HTML.Form.input_id(@form, @field.name)}
        name={Phoenix.HTML.Form.input_name(@form, @field.name)}
        value={Phoenix.HTML.Form.input_value(@form, @field.name)}
        placeholder={@field.placeholder}
        class="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
      />
      <p :if={@field.hint} class="mt-1 text-sm text-gray-500">{@field.hint}</p>
      <.errors :for={err <- (@form[@field.name] || %{errors: []}).errors} message={elem(err, 0)} />
    </div>
    """
  end

  # ───────────────────────────────────────────────────────────────────────────
  # Example: Custom Combobox with Creatable Support
  # ───────────────────────────────────────────────────────────────────────────

  defp render_combobox(assigns) do
    opts = assigns.field.opts || []
    creatable? = Keyword.get(opts, :creatable, false)
    
    assigns = assign(assigns, :creatable?, creatable?)

    ~H"""
    <div class={["mb-4", @field.wrapper_class]}>
      <label :if={@field.label} class="block text-sm font-medium text-gray-700 mb-1">
        {@field.label}
      </label>
      
      <%!-- Your combobox implementation here --%>
      <div class="relative">
        <input
          type="text"
          id={Phoenix.HTML.Form.input_id(@form, @field.name)}
          name={Phoenix.HTML.Form.input_name(@form, @field.name)}
          placeholder={@field.placeholder}
          class="w-full px-3 py-2 border border-gray-300 rounded-md"
        />
        
        <%!-- Creatable button (if enabled) --%>
        <button
          :if={@creatable?}
          type="button"
          phx-click="create_combobox_item"
          phx-value-field={@field.name}
          class="absolute right-2 top-2 text-sm text-blue-600 hover:text-blue-800"
        >
          + Create New
        </button>
      </div>
      
      <p :if={@field.hint} class="mt-1 text-sm text-gray-500">{@field.hint}</p>
    </div>
    """
  end

  # ───────────────────────────────────────────────────────────────────────────
  # Error Component
  # ───────────────────────────────────────────────────────────────────────────

  attr(:message, :string, required: true)

  defp errors(assigns) do
    ~H"""
    <p class="mt-1 text-sm text-red-600">{@message}</p>
    """
  end

  # Add more render_* functions for other field types...
end

# ─────────────────────────────────────────────────────────────────────────────
# 6.3 Theme Adapter Pattern
# ─────────────────────────────────────────────────────────────────────────────
#
# For large applications, you might want to create theme adapters that
# compose multiple UI libraries or provide consistent design tokens.
#
# Example structure:
#
# lib/my_app_web/form_builder/
# ├── theme.ex              # Base theme behaviour
# ├── default_theme.ex      # Default implementation
# ├── mishka_theme.ex       # MishkaChelekom adapter
# ├── daisy_theme.ex        # DaisyUI/Tailwind adapter
# └── custom_theme.ex       # Your app's custom theme
#
# ─────────────────────────────────────────────────────────────────────────────

# =============================================================================
# 7. AREAS OF ENHANCEMENT
# =============================================================================
#
# The following enhancements could improve the ash_form_builder library:
#
# ─────────────────────────────────────────────────────────────────────────────
# 7.1 Creatable Combobox Improvements
# ─────────────────────────────────────────────────────────────────────────────
#
# • Better value extraction: Currently uses regex to extract value from
#   create_label. Could pass the raw input value directly from the combobox.
#
# • Loading states: Show loading indicator while creating new items.
#
# • Error handling: Display inline errors when creation fails (e.g., duplicate
#   name validation).
#
# • Confirmation dialog: Optional confirmation before creating new items.
#
# • Bulk create: Allow creating multiple new items at once.
#
# ─────────────────────────────────────────────────────────────────────────────
# 7.2 Search Optimization
# ─────────────────────────────────────────────────────────────────────────────
#
# • Server-side pagination: For large datasets, paginate search results.
#
# • Caching: Cache frequently searched results to reduce database queries.
#
# • Debounce configuration: Make debounce configurable per-field.
#
# • Minimum search length: Configure minimum characters before searching.
#
# ─────────────────────────────────────────────────────────────────────────────
# 7.3 Nested Form Enhancements
# ─────────────────────────────────────────────────────────────────────────────
#
# • Sortable lists: Drag-and-drop reordering for has_many relationships.
#
# • Collapsible sections: Collapse/expand nested form sections.
#
# • Conditional rendering: Show/hide nested forms based on parent field values.
#
# • Deep nesting: Support for nested forms within nested forms.
#
# ─────────────────────────────────────────────────────────────────────────────
# 7.4 Validation & UX
# ─────────────────────────────────────────────────────────────────────────────
#
# • Inline validation: Real-time validation as users type.
#
# • Field-level permissions: Hide/disable fields based on user permissions.
#
# • Conditional fields: Show/hide fields based on other field values.
#
# • Multi-step forms: Wizard-style forms with progress indicators.
#
# • Form drafts: Auto-save form state to localStorage or database.
#
# ─────────────────────────────────────────────────────────────────────────────
# 7.5 Internationalization (i18n)
# ─────────────────────────────────────────────────────────────────────────────
#
# • Translatable labels: Support for GetText or similar i18n libraries.
#
# • Locale-aware formatting: Date, number, and currency formatting.
#
# • RTL support: Right-to-left language support.
#
# ─────────────────────────────────────────────────────────────────────────────
# 7.6 Performance
# ─────────────────────────────────────────────────────────────────────────────
#
# • Lazy loading: Load combobox options on demand.
#
# • Virtual scrolling: For large option lists in combobox.
#
# • Form optimization: Reduce LiveView payload size for large forms.
#
# =============================================================================
# 8. TESTING YOUR FORMS
# =============================================================================
#
# ─────────────────────────────────────────────────────────────────────────────
# 8.1 Unit Tests for Form Schema
# ─────────────────────────────────────────────────────────────────────────────
#
# test "clinic form has correct fields" do
#   schema = AshFormBuilder.Infer.infer_schema(MyApp.Healthcare.Clinic, :create)
#   
#   assert Enum.any?(schema.fields, &(&1.name == :name))
#   assert Enum.any?(schema.fields, &(&1.type == :multiselect_combobox))
# end
#
# ─────────────────────────────────────────────────────────────────────────────
# 8.2 Component Tests
# ─────────────────────────────────────────────────────────────────────────────
#
# test "form submission creates clinic", %{conn: conn} do
#   {:ok, view, _html} = live_isolated(conn, MyAppWeb.ClinicLive.Form)
#   
#   html =
#     view
#     |> form("#clinic-form", clinic: %{name: "Test Clinic"})
#     |> render_submit()
#   
#   assert html =~ "Clinic created successfully!"
# end
#
# ─────────────────────────────────────────────────────────────────────────────
# 8.3 Creatable Combobox Tests
# ─────────────────────────────────────────────────────────────────────────────
#
# test "creating new tag from combobox", %{conn: conn} do
#   {:ok, view, _html} = live_isolated(conn, MyAppWeb.ClinicLive.Form)
#   
#   # Trigger create event
#   {:noreply, _updated_socket} =
#     AshFormBuilder.FormComponent.handle_event(
#       "create_combobox_item",
#       %{
#         "field" => "tags",
#         "resource" => "Elixir.MyApp.Healthcare.Tag",
#         "action" => "create",
#         "creatable_value" => "New Tag"
#       },
#       socket
#     )
#   
#   # Verify tag was created
#   assert %MyApp.Healthcare.Tag{name: "New Tag"} = 
#            Ash.read_one!(MyApp.Healthcare.Tag, name: "New Tag")
# end
#
# =============================================================================
# 9. FILE UPLOADS
# =============================================================================
#
# AshFormBuilder provides declarative file upload support that bridges
# Phoenix LiveView's native upload lifecycle with Ash Framework.
#
# =============================================================================

# ─────────────────────────────────────────────────────────────────────────────
# 9.1 Resource with File Upload
# ─────────────────────────────────────────────────────────────────────────────

defmodule MyApp.Users.User do
  @moduledoc """
  User resource with file upload support.
  """

  use Ash.Resource,
    domain: MyApp.Users,
    extensions: [AshFormBuilder]

  attributes do
    uuid_primary_key :id
    attribute :name, :string, allow_nil?: false
    attribute :email, :string, allow_nil?: false
    attribute :avatar_path, :string
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [:name, :email]
      argument :avatar, :string, allow_nil?: true

      # Store uploaded file path in avatar_path attribute
      change fn changeset, _ ->
        case Ash.Changeset.get_argument(changeset, :avatar) do
          nil -> changeset
          path -> Ash.Changeset.change_attribute(changeset, :avatar_path, path)
        end
      end
    end

    update :update do
      accept [:name, :email]
      argument :avatar, :string, allow_nil?: true

      change fn changeset, _ ->
        case Ash.Changeset.get_argument(changeset, :avatar) do
          nil -> changeset
          path -> Ash.Changeset.change_attribute(changeset, :avatar_path, path)
        end
      end
    end
  end

  form do
    action :create
    submit_label "Create User"

    field :name do
      label "Full Name"
      required true
    end

    field :email do
      label "Email Address"
      type :email
      required true
    end

    field :avatar do
      type :file_upload
      label "Profile Photo"
      hint "JPEG or PNG, max 5 MB"

      opts upload: [
        cloud: MyApp.Buckets.Cloud,
        max_entries: 1,
        max_file_size: 5_000_000,
        accept: ~w(.jpg .jpeg .png)
      ]
    end
  end

  # Separate configuration for update form
  form do
    action :update
    submit_label "Save Changes"

    field :name do
      label "Full Name"
      required true
    end

    field :email do
      label "Email Address"
      type :email
      required true
    end

    field :avatar do
      type :file_upload
      label "Profile Photo"
      hint "Upload new photo to replace existing one"

      opts upload: [
        cloud: MyApp.Buckets.Cloud,
        max_entries: 1,
        max_file_size: 5_000_000,
        accept: ~w(.jpg .jpeg .png)
      ]
    end
  end
end

# ─────────────────────────────────────────────────────────────────────────────
# 9.2 Multiple File Uploads
# ─────────────────────────────────────────────────────────────────────────────

defmodule MyApp.Documents.Document do
  @moduledoc """
  Document resource with multiple file uploads.
  """

  use Ash.Resource,
    domain: MyApp.Documents,
    extensions: [AshFormBuilder]

  attributes do
    uuid_primary_key :id
    attribute :title, :string, allow_nil?: false
    attribute :file_paths, {:array, :string}, default: []
  end

  actions do
    create :create do
      accept [:title]
      argument :files, {:array, :string}, allow_nil?: true

      change fn changeset, _ ->
        case Ash.Changeset.get_argument(changeset, :files) do
          nil -> changeset
          paths -> Ash.Changeset.change_attribute(changeset, :file_paths, paths)
        end
      end
    end
  end

  form do
    action :create
    submit_label "Upload Documents"

    field :title do
      label "Document Title"
      required true
    end

    field :files do
      type :file_upload
      label "Attachments"
      hint "Upload multiple PDF or Word documents (max 5 files, 10 MB each)"

      opts upload: [
        cloud: MyApp.Buckets.Cloud,
        max_entries: 5,
        max_file_size: 10_000_000,
        accept: ~w(.pdf .doc .docx)
      ]
    end
  end
end

# ─────────────────────────────────────────────────────────────────────────────
# 9.3 LiveView Integration
# ─────────────────────────────────────────────────────────────────────────────

defmodule MyAppWeb.UserLive.Create do
  @moduledoc """
  LiveView for creating users with file uploads.
  """

  use MyAppWeb, :live_view

  def mount(_params, _session, socket) do
    form = MyApp.Users.User.Form.for_create(actor: socket.assigns.current_user)
    {:ok, assign(socket, form: form)}
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto px-4 py-8">
      <h1 class="text-3xl font-bold mb-6">Create User</h1>

      <.live_component
        module={AshFormBuilder.FormComponent}
        id="user-form"
        resource={MyApp.Users.User}
        form={@form}
      />
    </div>
    """
  end

  def handle_info({:form_submitted, MyApp.Users.User, user}, socket) do
    {:noreply,
     socket
     |> put_flash(:info, "User created successfully!")
     |> push_navigate(to: ~p"/users/#{user.id}")}
  end
end

# ─────────────────────────────────────────────────────────────────────────────
# 9.4 How File Uploads Work
# ─────────────────────────────────────────────────────────────────────────────

# 1. MOUNT PHASE:
#    - FormComponent.update/2 is called
#    - allow_file_uploads/2 loops through all :file_upload fields
#    - Phoenix.LiveView.allow_upload/3 is called for each field
#    - Upload configuration is applied (accept, max_entries, max_file_size)
#
# 2. UPLOAD PHASE:
#    - User selects file(s) via live_file_input
#    - Phoenix LiveView handles chunked upload
#    - Progress is displayed via live_img_preview and progress bars
#    - Validation errors shown for too_large, too_many_files, not_accepted
#
# 3. SUBMIT PHASE:
#    - User submits form
#    - FormComponent.handle_event("submit", ...) is called
#    - consume_file_uploads/2 is called BEFORE AshPhoenix.Form.submit/2
#    - For each upload field:
#      * Phoenix.LiveView.consume_uploaded_entries/3 is called
#      * Each entry is stored via Buckets.Cloud.insert/2
#      * Final file path is extracted from stored location
#    - File paths are merged into form parameters
#    - Ash action receives parameters with file paths
#    - Ash change function stores paths in resource attributes
#
# 4. RESULT:
#    - Form submission succeeds or fails based on Ash validations
#    - On success, file paths are persisted in database
#    - On error, form re-renders with validation errors, uploads preserved

# ─────────────────────────────────────────────────────────────────────────────
# 9.5 Testing File Uploads
# ─────────────────────────────────────────────────────────────────────────────

# defmodule MyAppWeb.UserLive.CreateTest do
#   use MyAppWeb.ConnCase, async: true
#   import Phoenix.LiveViewTest
#
#   test "uploading avatar creates user with file path", %{conn: conn} do
#     {:ok, view, _html} = live_isolated(conn, MyAppWeb.UserLive.Create)
#
#     # Select file for upload
#     upload =
#       file_input(view, "#user-form", :avatar, [
#         %{
#           name: "avatar.jpg",
#           content: :binary.copy(<<0xFF, 0xD8, 0xFF>>, 100),
#           type: "image/jpeg"
#         }
#       ])
#
#     # Simulate upload progress
#     render_upload(upload, 100)
#
#     # Submit form
#     view
#     |> form("#user-form", user: %{"name" => "John", "email" => "john@example.com"})
#     |> render_submit()
#
#     # Assert user was created
#     assert render(view) =~ "User created successfully!"
#
#     # Assert file was stored
#     user = MyApp.Users.get_user_by_email!("john@example.com")
#     assert user.avatar_path =~ "uploads/"
#     assert user.avatar_path =~ "avatar.jpg"
#   end
#
#   test "file too large shows error", %{conn: conn} do
#     {:ok, view, _html} = live_isolated(conn, MyAppWeb.UserLive.Create)
#
#     # Try to upload file larger than max_file_size (5 MB)
#     big_file = :binary.copy(<<0>>, 6_000_000)
#
#     upload =
#       file_input(view, "#user-form", :avatar, [
#         %{name: "huge.jpg", content: big_file, type: "image/jpeg"}
#       ])
#
#     html = render_upload(upload, 100)
#
#     # Assert error message is shown
#     assert html =~ "too large" or html =~ "File is too large"
#   end
# end

# =============================================================================
# END OF GUIDE
# =============================================================================
#
# For more information:
# • Ash Framework: https://hexdocs.pm/ash
# • Phoenix LiveView: https://hexdocs.pm/phoenix_live_view
# • MishkaChelekom: https://github.com/mishkacelekom/mishka_chelekom
#
# =============================================================================
