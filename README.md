# Ash Form Builder 🚀

A declarative form generation engine for [Ash Framework](https://ash-hq.org/) and [Phoenix LiveView](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html).

Define your form structures directly inside your `Ash.Resource` domain layer, and let the engine automatically generate the Phoenix form modules, nested configurations, and LiveView components.

## ✨ Features

* **🤖 Auto-Inference Engine** - Automatically infers form fields from your resource's `accept` list, including `many_to_many` relationships
* **� Domain Code Interface Integration** - Works seamlessly with Ash's `form_to_<action>` pattern for clean, policy-compliant LiveViews
* **🔍 Searchable Many-to-Many** - Built-in `:multiselect_combobox` type with searchable selection for many-to-many relationships
* **🎨 Customizable Themes** - Default HTML theme + full [MishkaChelekom](https://github.com/mishka-group/mishka_chelekom) component integration
* **🛠️ Declarative DSL** - Define form fields, types, and labels directly in your resource
* **🔄 Multiple Actions** - Support for both `:create` and `:update` forms with separate configurations
* **⚡ Self-Contained LiveComponent** - A ready-to-use `<.live_component>` that handles validation, submission, and nested form state automatically

---

## 📦 Installation

Add `ash_form_builder` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ash, "~> 3.0"},
    {:ash_phoenix, "~> 2.0"},
    {:ash_form_builder, github: "nagieeb0/ash_form_builder"}
  ]
end
```

Configure your theme in `config/config.exs`:

```elixir
# Default HTML theme
config :ash_form_builder, :theme, AshFormBuilder.Themes.Default

# MishkaChelekom theme (requires mishka_chelekom dependency)
config :ash_form_builder, :theme, AshFormBuilder.Theme.MishkaTheme
```

---

## 🚀 Quick Start

### 1. Define Your Resource with Auto-Inference

The simplest approach: just declare the action, and the form fields are auto-inferred from your resource's `accept` list.

```elixir
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

  form do
    action :create
    # Fields are auto-inferred from action.accept!
    # many_to_many relationships automatically use :multiselect_combobox
  end
end
```

### 2. Configure Domain Code Interfaces

Define `form_to_<action>` interfaces in your Domain for clean LiveView integration:

```elixir
defmodule MyApp.Billing do
  use Ash.Domain

  resources do
    resource MyApp.Billing.Clinic do
      define :form_to_create_clinic, action: :create
      define :form_to_update_clinic, action: :update
    end
  end
end
```

### 3. Create the LiveView (Zero Boilerplate!)

```elixir
defmodule MyAppWeb.ClinicLive.Form do
  use MyAppWeb, :live_view

  alias MyApp.Billing

  @impl true
  def mount(_params, _session, socket) do
    # No manual AshPhoenix.Form calls needed!
    form = Billing.Clinic.Form.for_create(actor: socket.assigns.current_user)
    {:ok, assign(socket, form: form)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto">
      <h1 class="text-2xl font-bold mb-4">Create Clinic</h1>

      <.live_component
        module={AshFormBuilder.FormComponent}
        id="clinic-form"
        resource={MyApp.Billing.Clinic}
        form={@form}
      />
    </div>
    """
  end

  @impl true
  def handle_info({:form_submitted, MyApp.Billing.Clinic, clinic}, socket) do
    {:noreply,
     socket
     |> put_flash(:info, "Clinic created!")
     |> push_navigate(to: ~p"/clinics/#{clinic}")}
  end
end
```

---

## 🔍 Many-to-Many with Searchable Combobox

For `many_to_many` relationships, the auto-inference engine creates a `:multiselect_combobox` field with searchable selection.

### Customizing the Search Behavior

```elixir
defmodule MyApp.Billing.Clinic do
  use Ash.Resource,
    domain: MyApp.Billing,
    extensions: [AshFormBuilder]

  # ... attributes and relationships ...

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
end
```

### Handling Search in LiveView

```elixir
defmodule MyAppWeb.ClinicLive.Form do
  use MyAppWeb, :live_view

  alias MyApp.Billing

  @impl true
  def mount(_params, _session, socket) do
    form = Billing.Clinic.Form.for_create(actor: socket.assigns.current_user)
    {:ok, assign(socket, form: form, doctor_options: preload_doctors())}
  end

  @impl true
  def handle_event("search_doctors", %{"query" => query}, socket) do
    doctors =
      Billing.Doctor
      |> Ash.Query.filter(name_contains: query)
      |> Billing.read!(actor: socket.assigns.current_user)
      |> Enum.map(&{&1.full_name, &1.id})

    {:noreply, push_event(socket, "update_combobox_options", %{
      field: "doctors",
      options: doctors
    })}
  end

  defp preload_doctors do
    Billing.list_doctors!()
    |> Enum.map(&{&1.full_name, &1.id})
  end
end
```

---

## 🎨 Themes

### Default Theme

Emits semantic HTML with minimal CSS class hooks — no framework dependency.

```elixir
config :ash_form_builder, :theme, AshFormBuilder.Themes.Default
```

### MishkaChelekom Theme

Full integration with [MishkaChelekom](https://github.com/mishka-group/mishka_chelekom) components.

**Setup:**

1. Generate the required components:

```bash
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
```

2. Configure the theme:

```elixir
config :ash_form_builder, :theme, AshFormBuilder.Theme.MishkaTheme
```

3. The `:multiselect_combobox` will now render as a full-featured MishkaChelekom combobox with search support!

---

## 🛠️ Advanced DSL Usage

### Explicit Field Configuration

While auto-inference works for most cases, you can customize fields explicitly:

```elixir
form do
  action :create
  submit_label "Create Clinic"

  field :name do
    label "Clinic Name"
    placeholder "Enter clinic name"
    required true
  end

  field :status do
    type :select
    options [{"Active", :active}, {"Inactive", :inactive}]
  end

  field :description do
    type :textarea
    rows 6
  end
end
```

### Nested Forms

For one-to-many relationships:

```elixir
form do
  action :create

  nested :appointments do
    label "Appointments"
    cardinality :many
    add_label "Add Appointment"
    remove_label "Remove"

    field :date do
      type :datetime
      required true
    end

    field :notes do
      type :textarea
    end
  end
end
```

### Multiple Forms per Resource

```elixir
defmodule MyApp.Todos.Todo do
  use Ash.Resource,
    domain: MyApp.Todos,
    extensions: [AshFormBuilder]

  # Create form
  form do
    action :create
    submit_label "Create Todo"

    field :title, label: "Title", required: true
    field :priority, type: :select, options: [{"Low", 1}, {"High", 2}]
  end

  # Update form with custom module name
  form do
    action :update
    module MyApp.Todos.Todo.UpdateForm
    submit_label "Update Todo"

    field :title, label: "Title"
    field :completed, type: :checkbox, label: "Done?"
  end
end
```

---

## 🔧 Introspection

Access the inferred form schema at runtime:

```elixir
# Get the complete schema
MyApp.Billing.Clinic.Form.schema()
# => %{
#   fields: [
#     %{name: :name, type: :text_input, required: true, ...},
#     %{name: :doctors, type: :multiselect_combobox, relationship: :doctors, ...}
#   ],
#   nested_forms: [...]
# }

# Get nested forms configuration for AshPhoenix.Form
MyApp.Billing.Clinic.Form.nested_forms()
# => [doctors: [type: :list, resource: MyApp.Billing.Doctor, ...]]
```

---

## ✅ Domain-Driven Validation Assurance

Using the Domain Code Interface ensures all Ash features work automatically:

**Policy Enforcement:**
```elixir
policies do
  policy action_type(:create) do
    authorize_if actor_present()
  end
end
```

**Validations:**
```elixir
validations do
  validate present([:name, :address])
  validate match(:phone, ~r/^\+?[\d\s-]+$/)
end
```

**Preparations & Changes:**
```elixir
changes do
  change atomic_update(:updated_at, &DateTime.utc_now/0)
end

preparations do
  prepare MyApp.SomePreparation
end
```

All are automatically applied when using `Clinic.Form.for_create/1` through the Domain Code Interface.

---

## 📚 Field Types Reference

| Ash Type | UI Type | Notes |
|----------|---------|-------|
| `:string` | `:text_input` | Standard text input |
| `:integer`, `:decimal`, `:float` | `:number` | Numeric input |
| `:boolean` | `:checkbox` | Boolean checkbox |
| `:date` | `:date` | Date picker |
| `:datetime`, `:utc_datetime` | `:datetime` | DateTime picker |
| `:enum`, atom with `values/0` | `:select` | Dropdown with options |
| `many_to_many` | `:multiselect_combobox` | Searchable multi-select |

**All Field Types:** `:text_input`, `:textarea`, `:select`, `:multiselect_combobox`, `:checkbox`, `:number`, `:email`, `:password`, `:date`, `:datetime`, `:hidden`, `:url`, `:tel`

---

## 📝 License

This project is MIT licensed.
