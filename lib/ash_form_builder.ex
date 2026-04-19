defmodule AshFormBuilder do
  @moduledoc """
  A Spark DSL extension for Ash Framework that automatically generates
  Phoenix LiveView forms from resource definitions.

  ## Key Features

  * **Auto-Inference Engine** - Automatically infers form fields from your
    resource's `accept` list, including `many_to_many` relationships
  * **Domain Code Interface Integration** - Works seamlessly with Ash's
    `form_to_<action>` pattern for clean LiveViews
  * **Customizable Themes** - Built-in MishkaChelekom theme with advanced
    searchable combobox support for many-to-many relationships

  ## Installation

  Add the extension to your resource:

      defmodule MyApp.Billing.Clinic do
        use Ash.Resource,
          domain: MyApp.Billing,
          extensions: [AshFormBuilder]

        attributes do
          uuid_primary_key :id
          attribute :name, :string, allow_nil?: false
          attribute :address, :string
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

        form do
          action :create
          # Fields are auto-inferred from action.accept
          # many_to_many relationships automatically use :multiselect_combobox
        end
      end

  ## Domain Code Interface Setup

  Configure your Domain with form-specific code interfaces:

      defmodule MyApp.Billing do
        use Ash.Domain

        resources do
          resource MyApp.Billing.Clinic do
            define :form_to_create_clinic, action: :create
            define :form_to_update_clinic, action: :update
          end
        end
      end

  ## Creating a Form in LiveView

      defmodule MyAppWeb.ClinicLive.Form do
        use MyAppWeb, :live_view

        @impl true
        def mount(_params, _session, socket) do
          # No manual AshPhoenix.Form calls needed!
          form = MyApp.Billing.Clinic.Form.for_create(
            actor: socket.assigns.current_user
          )
          {:ok, assign(socket, form: form)}
        end

        @impl true
        def render(assigns) do
          ~H\"\"\"
          <.live_component
            module={AshFormBuilder.FormComponent}
            id="clinic-form"
            resource={MyApp.Billing.Clinic}
            form={@form}
          />
          \"\"\"
        end

        @impl true
        def handle_info({:form_submitted, MyApp.Billing.Clinic, clinic}, socket) do
          {:noreply, push_navigate(socket, to: ~p"/clinics/" <> clinic.id)}
        end
      end

  ## Auto-Inference Engine

  The `AshFormBuilder.Infer` module automatically maps:

  | Ash Type          | UI Type                 |
  |-------------------|-------------------------|
  | `:string`         | `:text_input`           |
  | `:integer`        | `:number`               |
  | `:boolean`        | `:checkbox`             |
  | `:date`           | `:date`                 |
  | `:datetime`       | `:datetime`             |
  | `:enum`           | `:select`               |
  | `many_to_many`    | `:multiselect_combobox` |

  ## Many-to-Many with Searchable Combobox

  Auto-inferred `many_to_many` relationships use a searchable combobox.
  Customize the search behavior:

      form do
        action :create

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

  Handle search in your LiveView:

      def handle_event("search_doctors", %{"query" => query}, socket) do
        doctors =
          MyApp.Billing.Doctor
          |> Ash.Query.filter(name_contains: query)
          |> MyApp.Billing.read!(actor: socket.assigns.current_user)
          |> Enum.map(&{&1.full_name, &1.id})

        {:noreply, push_event(socket, "update_combobox_options", %{
          field: "doctors",
          options: doctors
        })}
      end

  ## Theme Configuration

  Configure the theme in `config/config.exs`:

      # Default HTML theme
      config :ash_form_builder, :theme, AshFormBuilder.Themes.Default

      # MishkaChelekom theme (requires mishka_chelekom dependency)
      config :ash_form_builder, :theme, AshFormBuilder.Theme.MishkaTheme

  ## Domain-Driven Validation Assurance

  Using the Domain Code Interface ensures:

  * **Policy Enforcement** - All Ash policies are checked automatically
  * **Full Validations** - Server-side validations run on every submit
  * **Atomic Updates** - Actions execute within transactions
  * **Error Rendering** - Validation errors render through the theme

  ## DSL Reference

  ### `form` Section

  | option          | type   | default       | description |
  |-----------------|--------|---------------|-------------|
  | `action`        | atom   | required      | Ash action to target |
  | `submit_label`  | string | `"Submit"`    | Submit button label |
  | `module`        | atom   | —             | Override generated module name |
  | `form_id`       | string | —             | HTML `id` for the `<form>` |
  | `wrapper_class` | string | `"space-y-4"` | CSS class on fields wrapper |

  ### `field` Options

  | option          | type    | default        | description |
  |-----------------|---------|----------------|-------------|
  | `label`         | string  | —              | Input label |
  | `type`          | atom    | `:text_input`  | Input type |
  | `placeholder`   | string  | —              | Placeholder text |
  | `required`      | boolean | `false`        | Required indicator |
  | `options`       | list    | `[]`           | Select options |
  | `opts`          | keyword | `[]`           | Custom UI options |

  **Field Types**: `:text_input`, `:textarea`, `:select`, `:multiselect_combobox`,
  `:checkbox`, `:number`, `:email`, `:password`, `:date`, `:datetime`, `:hidden`,
  `:url`, `:tel`

  **`:multiselect_combobox` opts**:
  * `search_event` - Event name for searching
  * `search_param` - Query param name (default: `"query"`)
  * `debounce` - Search debounce in ms (default: `300`)
  * `label_key` - Field for labels (default: `:name`)
  * `value_key` - Field for values (default: `:id`)
  * `creatable` - Allow creating new items via combobox (default: `false`)
  * `create_action` - Action to use for creating new items (default: `:create`)
  * `create_label` - Label template for create button (default: `"Create \"{value}\""`)

  ### `nested` Options

  | option           | type   | default    | description |
  |------------------|--------|------------|-------------|
  | `relationship`   | atom   | `:name`    | Relationship name |
  | `cardinality`    | atom   | `:many`    | `:many` or `:one` |
  | `label`          | string | —          | Fieldset legend |
  | `add_label`      | string | `"Add"`    | Add-button label |
  | `remove_label`   | string | `"Remove"` | Remove-button label |
  | `create_action`  | atom   | `:create`  | Nested create action |
  | `update_action`  | atom   | `:update`  | Nested update action |
  | `class`          | string | —          | Fieldset CSS class |

  ## Introspection

  Access the inferred form schema:

      MyApp.Billing.Clinic.Form.schema()
      # => %{fields: [...], nested_forms: [...]}

  Get nested forms configuration:

      MyApp.Billing.Clinic.Form.nested_forms()
      # => [doctors: [type: :list, resource: MyApp.Billing.Doctor, ...]]

  ## Modules

  * `AshFormBuilder.Infer` - Auto-inference engine
  * `AshFormBuilder.Theme` - Theme behaviour
  * `AshFormBuilder.Theme.MishkaTheme` - MishkaChelekom theme
  * `AshFormBuilder.DomainIntegration` - Domain Code Interface docs
  """

  use Spark.Dsl.Extension,
    sections: AshFormBuilder.Dsl.sections(),
    transformers: AshFormBuilder.Dsl.transformers()
end
