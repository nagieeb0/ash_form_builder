defmodule AshFormBuilder.DomainIntegration do
  @moduledoc """
  Domain Code Interface Integration for AshFormBuilder.

  This module documents how to configure Ash.Domain resources with Code Interfaces
  to automatically generate `form_to_<action>` functions that work seamlessly
  with AshFormBuilder.

  ## Overview

  Ash's Domain Code Interfaces allow you to define explicit entry points to your
  resources. When combined with AshFormBuilder, this provides:

  1. **Declarative Form Setup** - No manual `AshPhoenix.Form.for_create/3` calls
  2. **Automatic Policy Enforcement** - All Ash policies respected out-of-the-box
  3. **Validation & Atomics** - Full Ash validation and atomic update support
  4. **Clean LiveViews** - Minimal boilerplate in LiveView modules

  ## Configuration

  ### 1. Define the Resource with Form DSL

      defmodule MyApp.Billing.Clinic do
        use Ash.Resource,
          domain: MyApp.Billing,
          extensions: [AshFormBuilder]

        attributes do
          uuid_primary_key :id
          attribute :name, :string, allow_nil?: false
          attribute :address, :string
          attribute :phone, :string
        end

        relationships do
          many_to_many :doctors, MyApp.Billing.Doctor do
            through MyApp.Billing.ClinicDoctor
            source_attribute_on_join_resource :clinic_id
            destination_attribute_on_join_resource :doctor_id
          end
        end

        actions do
          defaults [:create, :read, :update, :destroy]
        end

        # CREATE form - auto-infers fields from :create action
        form do
          action :create
          submit_label "Create Clinic"

          # Fields are auto-inferred from the action's accept list
          # many_to_many relationships automatically become :multiselect_combobox
        end

        # UPDATE form - separate configuration for :update action
        form do
          action :update
          submit_label "Save Changes"

          # Can customize fields differently for update forms
          field :name do
            hint "Changing the name will require re-verification"
          end
        end
      end

  ### 2. Configure the Domain with Code Interfaces

      defmodule MyApp.Billing do
        use Ash.Domain

        resources do
          resource MyApp.Billing.Clinic do
            # Standard CRUD
            define :create_clinic, action: :create
            define :update_clinic, action: :update
            define :get_clinic, action: :read, get_by: [:id]

            # Form-specific interfaces (these auto-generate form_to_* functions)
            define :form_to_create_clinic, action: :create
            define :form_to_update_clinic, action: :update
          end

          resource MyApp.Billing.Doctor do
            define :create_doctor, action: :create
            define :list_doctors, action: :read
          end
        end
      end

  ### 3. Create the LiveView with Zero Boilerplate

  **Create Form:**

      defmodule MyAppWeb.ClinicLive.Form do
        use MyAppWeb, :live_view

        alias MyApp.Billing

        @impl true
        def mount(_params, _session, socket) do
          # Use the generated Form helper with Domain Code Interface
          form = Billing.Clinic.Form.for_create(actor: socket.assigns.current_user)

          {:ok, assign(socket, form: form, mode: :create)}
        end

        @impl true
        def render(assigns) do
          ~H\"\"\"
          <div class="max-w-2xl mx-auto">
            <h1 class="text-2xl font-bold mb-4">Create Clinic</h1>

            <.live_component
              module={AshFormBuilder.FormComponent}
              id="clinic-form"
              resource={MyApp.Billing.Clinic}
              form={@form}
            />
          </div>
          \"\"\"
        end

        @impl true
        def handle_info({:form_submitted, MyApp.Billing.Clinic, clinic}, socket) do
          {:noreply,
           socket
           |> put_flash(:info, "Clinic created successfully!")
           |> push_navigate(to: ~p"/clinics/\#{clinic.id}")}
        end
      end

  **Update Form:**

      defmodule MyAppWeb.ClinicLive.Edit do
        use MyAppWeb, :live_view

        alias MyApp.Billing

        @impl true
        def mount(%{"id" => id}, _params, _session, socket) do
          # Get existing record
          clinic = Billing.get_clinic!(id, actor: socket.assigns.current_user)

          # for_update/2 automatically preloads required relationships
          # and populates the form with current values
          form = Billing.Clinic.Form.for_update(clinic, actor: socket.assigns.current_user)

          {:ok, assign(socket, form: form, mode: :edit)}
        end

        @impl true
        def render(assigns) do
          ~H\"\"\"
          <div class="max-w-2xl mx-auto">
            <h1 class="text-2xl font-bold mb-4">Edit Clinic</h1>

            <.live_component
              module={AshFormBuilder.FormComponent}
              id="clinic-edit-form"
              resource={MyApp.Billing.Clinic}
              form={@form}
            />
          </div>
          \"\"\"
        end

        @impl true
        def handle_info({:form_submitted, MyApp.Billing.Clinic, clinic}, socket) do
          {:noreply,
           socket
           |> put_flash(:info, "Clinic updated successfully!")
           |> push_navigate(to: ~p"/clinics/\#{clinic.id}")}
        end
      end

  ## How It Works

  ### Ash Domain Code Interfaces

  When you define `define :form_to_create_clinic, action: :create`, Ash automatically:

  1. Generates a `form_to_create_clinic/2` function on your Domain
  2. Wraps the action with proper argument handling
  3. Applies all policies, validations, and preparations

  ### AshFormBuilder Integration

  The `Clinic.Form` module (generated by AshFormBuilder) provides:

  1. `for_create/1` - Creates an AshPhoenix.Form with nested_forms pre-configured
  2. `schema/0` - Returns the inferred form schema for introspection
  3. `nested_forms/0` - Returns the AshPhoenix.Form forms configuration

  ### Validation & Policy Assurance

  By using the Domain Code Interface path, you get:

  **Full Policy Enforcement**

      # Policies defined on the resource are automatically enforced
      policies do
        policy action_type(:create) do
          authorize_if actor_present()
        end
      end

  **Complete Validation**

      # All validations run server-side on submit
      validations do
        validate present([:name, :address])
      end

  **Atomic Updates**

      # Atomic updates happen within the same transaction
      changes do
        change atomic_update(:updated_at, &DateTime.utc_now/0)
      end

  **Preparations**

      # Preparations run before the action executes
      preparations do
        prepare MyApp.SomePreparation
      end

  ## Advanced: Many-to-Many with Searchable Combobox

  For many-to-many relationships, the auto-inference engine creates a
  `:multiselect_combobox` field. Here's how to handle search:

  ### Resource Configuration

      defmodule MyApp.Billing.Clinic do
        # ... attributes and relationships

        # Create form configuration
        form do
          action :create

          # Customize the combobox search behavior
          field :doctors do
            type :multiselect_combobox
            opts [
              search_event: "search_doctors",
              search_param: "query",
              debounce: 300,
              label_key: :full_name,
              value_key: :id
            ]
          end
        end

        # Update form - same combobox config, but existing selections auto-load
        form do
          action :update

          field :doctors do
            type :multiselect_combobox
            opts [
              search_event: "search_doctors",
              search_param: "query",
              debounce: 300,
              label_key: :full_name,
              value_key: :id
            ]
          end
        end
      end

  ### LiveView with Search Handler

  **Create Form:**

      defmodule MyAppWeb.ClinicLive.Form do
        use MyAppWeb, :live_view

        alias MyApp.Billing

        @impl true
        def mount(_params, _session, socket) do
          form = Billing.Clinic.Form.for_create(actor: socket.assigns.current_user)

          {:ok,
           socket
           |> assign(form: form)
           |> assign(doctor_options: preload_doctor_options())}
        end

        @impl true
        def render(assigns) do
          ~H\"\"\"
          <div class="max-w-2xl mx-auto">
            <.live_component
              module={AshFormBuilder.FormComponent}
              id="clinic-form"
              resource={MyApp.Billing.Clinic}
              form={@form}
              combobox_options={%{doctors: @doctor_options}}
            />
          </div>
          \"\"\"
        end

        # Handle combobox search events
        @impl true
        def handle_event("search_doctors", %{"query" => query}, socket) do
          doctors =
            Billing.Doctor
            |> Ash.Query.filter(name_contains: query)
            |> Billing.read!(actor: socket.assigns.current_user)

          options = Enum.map(doctors, &{&1.full_name, &1.id})

          {:noreply, push_event(socket, "update_combobox_options", %{
            field: "doctors",
            options: options
          })}
        end

        defp preload_doctor_options do
          Billing.list_doctors!()
          |> Enum.map(&{&1.full_name, &1.id})
        end
      end

  **Update Form with Search:**

      defmodule MyAppWeb.ClinicLive.Edit do
        use MyAppWeb, :live_view

        alias MyApp.Billing

        @impl true
        def mount(%{"id" => id}, _params, _session, socket) do
          # Get existing clinic with relationships loaded
          clinic = Billing.get_clinic!(id, actor: socket.assigns.current_user)

          # for_update/2 auto-preloads required relationships
          form = Billing.Clinic.Form.for_update(clinic, actor: socket.assigns.current_user)

          {:ok,
           socket
           |> assign(form: form, mode: :edit)
           |> assign(doctor_options: load_doctor_options(clinic.doctors))}
        end

        @impl true
        def render(assigns) do
          ~H\"\"\"
          <div class="max-w-2xl mx-auto">
            <h1 class="text-2xl font-bold mb-4">Edit Clinic</h1>

            <.live_component
              module={AshFormBuilder.FormComponent}
              id="clinic-edit-form"
              resource={MyApp.Billing.Clinic}
              form={@form}
              combobox_options={%{doctors: @doctor_options}}
            />
          </div>
          \"\"\"
        end

        # Same search handler works for both create and update forms
        @impl true
        def handle_event("search_doctors", %{"query" => query}, socket) do
          doctors =
            Billing.Doctor
            |> Ash.Query.filter(name_contains: query)
            |> Billing.read!(actor: socket.assigns.current_user)

          options = Enum.map(doctors, &{&1.full_name, &1.id})

          {:noreply, push_event(socket, "update_combobox_options", %{
            field: "doctors",
            options: options
          })}
        end

        defp load_doctor_options(doctors) do
          Enum.map(doctors, &{&1.full_name, &1.id})
        end
      end

  ## Error Handling

  Ash validation errors are automatically rendered by the theme:

  ### Standard Ash Errors

      # Required field errors
      errors: [%{field: :name, message: "is required"}]

      # Custom validation errors
      validate match(:phone, ~r/^\\+?[\\d]+$/)  # => "must match the pattern +?[\\d]+"

  ### Theme Error Rendering

  The `MishkaTheme` renders errors via MishkaChelekom's error styling:

      <.text_field
        field={@form[:name]}
        label="Name"
        errors={@form[:name].errors}
      />

  ## Comparison: With vs Without Domain Code Interfaces

  ### Without (Manual Approach)

  **Create Form:**

      def mount(_params, _session, socket) do
        # Manual form creation
        form =
          AshPhoenix.Form.for_create(
            MyApp.Billing.Clinic,
            :create,
            actor: socket.assigns.current_user,
            forms: [
              # Manual nested form configuration
              doctors: [
                type: :list,
                resource: MyApp.Billing.Doctor,
                create_action: :create
              ]
            ]
          )
          |> Phoenix.Component.to_form()

        {:ok, assign(socket, form: form)}
      end

  **Update Form:**

      def mount(%{"id" => id}, _params, _session, socket) do
        clinic = MyApp.Billing.get_clinic!(id, actor: socket.assigns.current_user)

        # Manual preloading of relationships
        clinic = Ash.load!(clinic, [:doctors], actor: socket.assigns.current_user)

        form =
          AshPhoenix.Form.for_update(
            clinic,
            :update,
            actor: socket.assigns.current_user,
            forms: [
              doctors: [
                type: :list,
                resource: MyApp.Billing.Doctor,
                create_action: :create,
                update_action: :update
              ]
            ]
          )
          |> Phoenix.Component.to_form()

        {:ok, assign(socket, form: form)}
      end

  ### With (Domain-Driven)

  **Create Form:**

      def mount(_params, _session, socket) do
        # All configuration comes from the DSL
        form = MyApp.Billing.Clinic.Form.for_create(actor: socket.assigns.current_user)

        {:ok, assign(socket, form: form)}
      end

  **Update Form:**

      def mount(%{"id" => id}, _params, _session, socket) do
        # for_update/2 handles everything:
        # - Auto-preloads required relationships
        # - Populates form with current values
        # - Configures nested forms from DSL
        form = MyApp.Billing.Clinic.Form.for_update(
          MyApp.Billing.get_clinic!(id),
          actor: socket.assigns.current_user
        )

        {:ok, assign(socket, form: form)}
      end

  ## Debugging

  Inspect the inferred schema for any action:

      # Schema for create form
      MyApp.Billing.Clinic.Form.for_create().schema
      # => %{
      #   fields: [
      #     %{name: :name, type: :text_input, required: true, ...},
      #     %{name: :doctors, type: :multiselect_combobox, relationship: :doctors, ...}
      #   ],
      #   nested_forms: [
      #     %{name: :doctors, cardinality: :many, ...}
      #   ],
      #   required_preloads: [:doctors]
      # }

      # Schema for update form (includes required_preloads)
      MyApp.Billing.Clinic.Form.schema()
      # => %{
      #   fields: [...],
      #   nested_forms: [...],
      #   required_preloads: [:doctors]  # Auto-detected many_to_many relationships
      # }

  Check nested forms config:

      MyApp.Billing.Clinic.Form.nested_forms()
      # => [
      #   doctors: [
      #     type: :list,
      #     resource: MyApp.Billing.Doctor,
      #     create_action: :create,
      #     update_action: :update
      #   ]
      # ]

  ## Key Differences: Create vs Update Forms

  | Aspect | Create Form | Update Form |
  |--------|-------------|-------------|
  | Helper | `for_create/1` | `for_update/2` |
  | Record | Not required | First argument |
  | Preloading | N/A | Auto-preloads `many_to_many` |
  | Field Values | Empty/default | Populated from record |
  | Submit Action | `:create` | `:update` |

  """

  # This module is documentation-only
end
