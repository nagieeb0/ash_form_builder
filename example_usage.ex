# =============================================================================
# AshFormBuilder - Complete Integration Example
# =============================================================================
#
# This file demonstrates a real-world scenario:
# - A Clinic resource with many-to-many relationship to Specialties
# - Domain Code Interface configuration
# - Phoenix LiveView using the Domain function and MishkaTheme
#
# =============================================================================

# -----------------------------------------------------------------------------
# 1. THE ASH RESOURCE (Clinic with many-to-many Specialties)
# -----------------------------------------------------------------------------

defmodule MyApp.Healthcare.Clinic do
  @moduledoc """
  Clinic resource demonstrating AshFormBuilder with many-to-many relationship.
  """

  use Ash.Resource,
    domain: MyApp.Healthcare,
    extensions: [AshFormBuilder]

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

  relationships do
    # Many-to-many relationship with Specialty
    # This will automatically render as :multiselect_combobox
    many_to_many :specialties, MyApp.Healthcare.Specialty do
      through MyApp.Healthcare.ClinicSpecialty
      source_attribute_on_join_resource :clinic_id
      destination_attribute_on_join_resource :specialty_id
    end
  end

  actions do
    defaults [:create, :read, :update, :destroy]

    create :create do
      accept [:name, :address, :phone, :email, :website, :is_active, :specialties]
    end

    update :update do
      accept [:name, :address, :phone, :email, :website, :is_active, :specialties]
    end
  end

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

  form do
    action :create
    submit_label "Create Clinic"
    wrapper_class "space-y-6"

    # Auto-inferred fields from action.accept:
    # :name -> :text_input (required)
    # :address -> :text_input (required)
    # :phone -> :text_input
    # :email -> :text_input
    # :website -> :url
    # :is_active -> :checkbox
    # :specialties -> :multiselect_combobox (many_to_many!)

    # -------------------------------------------------------------------------
    # Explicit overrides for customization
    # -------------------------------------------------------------------------

    field :name do
      label "Clinic Name"
      placeholder "e.g., Downtown Medical Center"
      required true
    end

    field :address do
      label "Street Address"
      type :textarea
      placeholder "Full address including city and zip"
      rows 3
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

    # -------------------------------------------------------------------------
    # Many-to-Many: Searchable Combobox for Specialties
    # -------------------------------------------------------------------------

    field :specialties do
      type :multiselect_combobox
      label "Medical Specialties"
      placeholder "Search specialties..."
      required false

      # MishkaChelekom combobox customization via opts
      opts [
        # Event name for LiveView search handler
        search_event: "search_specialties",

        # Debounce delay for search input (ms)
        debounce: 300,

        # Field to use for option labels (from Specialty resource)
        label_key: :name,

        # Field to use for option values (from Specialty resource)
        value_key: :id,

        # Hint shown below the combobox
        hint: "Search and select all applicable specialties"
      ]
    end

    # -------------------------------------------------------------------------
    # Many-to-Many: Creatable Combobox for Tags
    # Allows users to create new tags on-the-fly
    # -------------------------------------------------------------------------

    field :tags do
      type :multiselect_combobox
      label "Tags"
      placeholder "Search or create tags..."
      required false

      # Enable creatable functionality
      opts [
        # Allow creating new items directly from the combobox
        creatable: true,

        # Action to use for creating new items (default: :create)
        create_action: :create,

        # Custom label for the create button
        # The \"\" will be replaced with the user's input
        create_label: "Create \"\"",

        # Event name for LiveView search handler
        search_event: "search_tags",

        # Debounce delay for search input (ms)
        debounce: 300,

        # Field to use for option labels (from Tag resource)
        label_key: :name,

        # Field to use for option values (from Tag resource)
        value_key: :id,

        # Hint shown below the combobox
        hint: "Type to search existing tags or create a new one"
      ]
    end
  end
end

# -----------------------------------------------------------------------------
# SUPPORTING RESOURCES (Specialty and Join Resource)
# -----------------------------------------------------------------------------

defmodule MyApp.Healthcare.Specialty do
  @moduledoc "Medical specialty (e.g., Cardiology, Pediatrics)"

  use Ash.Resource, domain: MyApp.Healthcare

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

defmodule MyApp.Healthcare.ClinicSpecialty do
  @moduledoc "Join resource for Clinic-Specialty many-to-many"

  use Ash.Resource, domain: MyApp.Healthcare

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

# -----------------------------------------------------------------------------
# 2. THE ASH DOMAIN - Code Interface Configuration
# -----------------------------------------------------------------------------

defmodule MyApp.Healthcare do
  @moduledoc """
  Healthcare domain with Code Interfaces for form generation.

  The `define :form_to_<action>` pattern enables clean LiveView integration
  by generating `form_to_create_clinic/2` and `form_to_update_clinic/2`
  functions that work seamlessly with AshFormBuilder.
  """

  use Ash.Domain

  resources do
    # Clinic resource with form-specific code interfaces
    resource MyApp.Healthcare.Clinic do
      # Standard CRUD
      define :list_clinics, action: :read
      define :get_clinic, action: :read, get_by: [:id]

      # Domain Code Interfaces for forms
      # These auto-generate form_to_create_clinic/2 and form_to_update_clinic/2
      define :form_to_create_clinic, action: :create
      define :form_to_update_clinic, action: :update
    end

    # Specialty resource (for combobox search)
    resource MyApp.Healthcare.Specialty do
      define :list_specialties, action: :read
      define :search_specialties, action: :read
    end
  end
end

# -----------------------------------------------------------------------------
# 3. THE PHOENIX LIVEVIEW - Using Domain Function and MishkaTheme
# -----------------------------------------------------------------------------

defmodule MyAppWeb.ClinicLive.Form do
  @moduledoc """
  LiveView for creating/editing Clinics using AshFormBuilder.

  This demonstrates:
  - Zero manual AshPhoenix.Form calls
  - Domain Code Interface usage (form_to_create_clinic)
  - MishkaTheme with searchable combobox for many-to-many
  - Automatic policy enforcement and validation
  """

  use MyAppWeb, :live_view

  alias MyApp.Healthcare

  # ===========================================================================
  # MOUNT - Creating the Form via Domain Code Interface
  # ===========================================================================

  @impl true
  def mount(%{"id" => id} = _params, _session, socket) do
    # EDIT MODE: Update existing clinic
    # The form helper automatically preloads :specialties for many_to_many
    clinic = Healthcare.get_clinic!(id, load: [:specialties], actor: socket.assigns.current_user)
    form = Healthcare.Clinic.Form.for_update(clinic, actor: socket.assigns.current_user)

    {:ok,
     socket
     |> assign(:page_title, "Edit Clinic")
     |> assign(:form, form)
     |> assign(:mode, :edit)
     |> assign(:specialty_options, load_specialty_options(clinic.specialties))}
  end

  def mount(_params, _session, socket) do
    # CREATE MODE: New clinic
    # Uses Domain Code Interface via the generated Form helper
    form = Healthcare.Clinic.Form.for_create(actor: socket.assigns.current_user)

    {:ok,
     socket
     |> assign(:page_title, "New Clinic")
     |> assign(:form, form)
     |> assign(:mode, :create)
     |> assign(:specialty_options, load_specialty_options([]))}
  end

  # ===========================================================================
  # RENDER - Using FormComponent with MishkaTheme
  # ===========================================================================

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-3xl mx-auto px-4 py-8">
      <h1 class="text-3xl font-bold mb-6 text-base-content"><%= @page_title %></h1>

      <div class="card bg-base-100 shadow-xl">
        <div class="card-body">
          <%!
            # The FormComponent uses the configured theme (MishkaTheme)
            # which renders:
            # - Standard fields with MishkaChelekom components
            # - :multiselect_combobox for specialties with search support
          %>
          <.live_component
            module={AshFormBuilder.FormComponent}
            id="clinic-form"
            resource={MyApp.Healthcare.Clinic}
            form={@form}
            theme_opts={[
              # Pass specialty options for the combobox
              combobox_options: %{specialties: @specialty_options},
              # Target for search events
              target: @myself
            ]}
          />
        </div>
      </div>
    </div>
    """
  end

  # ===========================================================================
  # SEARCH HANDLER - For Combobox Many-to-Many
  # ===========================================================================

  @impl true
  def handle_event("search_specialties", %{"query" => query}, socket) do
    # Search specialties based on user input
    # This is triggered by the combobox search in MishkaTheme
    specialties =
      MyApp.Healthcare.Specialty
      |> Ash.Query.filter(name_contains: query)
      |> MyApp.Healthcare.read!(actor: socket.assigns.current_user)

    options = Enum.map(specialties, &{&1.name, &1.id})

    # Push event to update combobox options dynamically
    {:noreply, push_event(socket, "update_combobox_options", %{
      field: "specialties",
      options: options
    })}
  end

  # ===========================================================================
  # SUCCESS HANDLER
  # ===========================================================================

  @impl true
  def handle_info({:form_submitted, MyApp.Healthcare.Clinic, clinic}, socket) do
    message = if socket.assigns.mode == :create, do: "Clinic created!", else: "Clinic updated!"

    {:noreply,
     socket
     |> put_flash(:info, message)
     |> push_navigate(to: ~p"/clinics/#{clinic.id}")}
  end

  # ===========================================================================
  # PRIVATE HELPERS
  # ===========================================================================

  defp load_specialty_options(specialties) do
    # Preload specialty options for the combobox
    # Can be called with existing specialties (edit) or empty list (create)
    Enum.map(specialties, &{&1.name, &1.id})
  end
end

# -----------------------------------------------------------------------------
# 4. CONFIGURATION
# -----------------------------------------------------------------------------

# In config/config.exs:
#
#   config :ash_form_builder, :theme, AshFormBuilder.Theme.MishkaTheme
#
# In lib/my_app_web.ex (your web module):
#
#   def live_view do
#     quote do
#       use Phoenix.LiveView,
#         layout: {MyAppWeb.Layouts, :app}
#
#       # Import MishkaChelekom components for your own templates
#       import MishkaChelekom.Components.Combobox
#       import MishkaChelekom.Components.TextField
#       # ... etc
#     end
#   end

# -----------------------------------------------------------------------------
# 5. VALIDATION & POLICY ASSURANCE EXPLANATION
# -----------------------------------------------------------------------------
#
# When using the Domain Code Interface pattern (form_to_create_clinic/2),
# ALL Ash Framework features are automatically respected:
#
# 1. POLICY ENFORCEMENT
#    - The 'authorize_if actor_present()' policy in Clinic is checked
#    - Unauthorized users receive automatic error messages
#    - Happens BEFORE form processing begins
#
# 2. VALIDATIONS
#    - 'validate present([:name, :address])' runs on every submit
#    - 'validate string_length(:name, ...)' enforces constraints
#    - Errors render through MishkaTheme's error styling
#
# 3. ATOMIC UPDATES
#    - The 'timestamps()' change updates :inserted_at/:updated_at
#    - All changes execute within a database transaction
#    - Rollback on any failure
#
# 4. PREPARATIONS
#    - Any 'prepare' steps in your action run before form processing
#    - Allows data enrichment or transformation
#
# 5. ERROR RENDERING
#    - Ash form errors are in 'form[field].errors'
#    - MishkaTheme passes these to components via 'errors={...}' prop
#    - Components render errors using MishkaChelekom styling
#
# The UI Adapter (MishkaTheme) does NOT need to know about Ash policies
# or validations - it simply renders standard Ash form errors that are
# automatically populated by the Domain Code Interface.
#
# =============================================================================
# END OF EXAMPLE
# =============================================================================
