# Ash Form Builder 🚀

> ⚠️ **EXPERIMENTAL - USE AT YOUR OWN RISK** ⚠️
> 
> This package is under active development. API may change without notice.
> Breaking changes are likely in minor versions. Not recommended for critical
> production systems without thorough testing.
> 
> **Status**: Alpha/Experimental | **Version**: 0.1.0

A declarative form generation engine for [Ash Framework](https://ash-hq.org/) and [Phoenix LiveView](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html).

Define your form structures directly inside your `Ash.Resource` domain layer, and let the engine automatically generate the Phoenix form modules, nested configurations, and LiveView components.

## ✨ Features

* **🤖 Auto-Inference Engine** - Automatically infers form fields from your resource's `accept` list, including `many_to_many` relationships
* **🔗 Domain Code Interface Integration** - Works seamlessly with Ash's `form_to_<action>` pattern for clean, policy-compliant LiveViews
* **🔍 Searchable Many-to-Many** - Built-in `:multiselect_combobox` type with searchable selection for many-to-many relationships
* **✨ NEW: Creatable Combobox** - Create related records on-the-fly directly from the form UI
* **🔗 Has Many Nested Forms** - Dynamic add/remove for child records (subtasks, order items, etc.)
* **🎨 Customizable Themes** - Default HTML theme + full [MishkaChelekom](https://github.com/mishka-group/mishka_chelekom) component integration
* **🛠️ Declarative DSL** - Define form fields, types, and labels directly in your resource
* **🔄 Multiple Actions** - Support for both `:create` and `:update` forms with separate configurations
* **⚡ Self-Contained LiveComponent** - A ready-to-use `<.live_component>` that handles validation, submission, and nested form state automatically
* **🔐 Policy Enforcement** - All Ash policies and validations are automatically respected

---

## 📦 Installation

Add `ash_form_builder` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ash, "~> 3.0"},
    {:ash_phoenix, "~> 2.0"},
    # ⚠️ EXPERIMENTAL - Use at your own risk
    {:ash_form_builder, "~> 0.1.0"}
    # Or from GitHub for latest:
    # {:ash_form_builder, github: "nagieeb0/ash_form_builder"}
  ]
end
```

Then run:
```bash
mix deps.get
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
    extensions: [AshFormBuilder]  # ← Add this extension

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

### 3. Use in LiveView

```elixir
defmodule MyAppWeb.ClinicLive.Form do
  use MyAppWeb, :live_view

  alias MyApp.Billing

  def mount(_params, _session, socket) do
    # Zero manual AshPhoenix.Form calls!
    form = Billing.Clinic.Form.for_create(actor: socket.assigns.current_user)
    {:ok, assign(socket, form: form)}
  end

  def render(assigns) do
    ~H"""
    <.live_component
      module={AshFormBuilder.FormComponent}
      id="clinic-form"
      resource={MyApp.Billing.Clinic}
      form={@form}
    />
    """
  end

  def handle_info({:form_submitted, MyApp.Billing.Clinic, clinic}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/clinics/#{clinic.id}")}
  end
end
```

---

## 🎯 Key Features

### Auto-Inference Engine

Fields are automatically mapped from Ash types to UI components:

| Ash Type          | UI Type                 |
|-------------------|-------------------------|
| `:string`         | `:text_input`           |
| `:integer`        | `:number`               |
| `:boolean`        | `:checkbox`             |
| `:date`           | `:date`                 |
| `:datetime`       | `:datetime`             |
| `:atom` + `one_of`| `:select`               |
| `many_to_many`    | `:multiselect_combobox` |

### Creatable Combobox ⭐ NEW

Allow users to create new related records on-the-fly:

```elixir
form do
  field :tags do
    type :multiselect_combobox
    label "Tags"
    placeholder "Search or create tags..."
    
    opts [
      creatable: true,              # ← Enable creating new items
      create_action: :create,
      create_label: "Create \"\"",
      search_event: "search_tags",
      debounce: 300,
      label_key: :name,
      value_key: :id
    ]
  end
end
```

### Nested Forms (has_many)

Dynamic add/remove for child records:

```elixir
form do
  nested :subtasks do
    label "Subtasks"
    cardinality :many
    add_label "Add Subtask"
    
    field :title do
      label "Subtask"
      required true
    end
  end
end
```

---

## 📚 Documentation

### Guides

Comprehensive guides are available in the `guides/` directory:

1. **[Todo App Integration](guides/todo_app_integration.exs)** - Complete step-by-step tutorial
2. **[Relationships Guide](guides/relationships_guide.exs)** - has_many vs many_to_many, filtering, limits
3. **[Example Usage](example_usage.exs)** - Reference documentation with all features

### Module Documentation

Generate local docs:
```bash
mix docs
```

---

## ⚠️ Experimental Status

**This package is EXPERIMENTAL and under active development.**

### What This Means

- ✅ Core functionality is working and tested
- ⚠️ API may change without notice
- ⚠️ Breaking changes likely in minor versions (0.x.y)
- ⚠️ Not all edge cases are handled
- ⚠️ Documentation may be incomplete

### For Production Use

If you choose to use this in production:

1. **Pin to exact version**: `{:ash_form_builder, "== 0.1.0"}`
2. **Test thoroughly** before deployment
3. **Monitor the repository** for updates and breaking changes
4. **Be prepared** to handle breaking changes on upgrade
5. **Consider contributing** fixes and improvements

### Roadmap to 1.0

Planned features for stable release:

- [ ] Better creatable value extraction
- [ ] Loading states for async operations
- [ ] Inline error handling
- [ ] i18n support via GetText
- [ ] Field-level permissions
- [ ] Conditional field rendering
- [ ] Multi-step form wizards
- [ ] Form draft auto-save
- [ ] More comprehensive test coverage

---

## 🔧 Configuration

### Theme System

AshFormBuilder uses a theme system for UI customization:

```elixir
# config/config.exs

# Default theme (semantic HTML)
config :ash_form_builder, :theme, AshFormBuilder.Themes.Default

# MishkaChelekom theme (requires mishka_chelekom dependency)
config :ash_form_builder, :theme, AshFormBuilder.Theme.MishkaTheme

# Custom theme (implement AshFormBuilder.Theme behaviour)
config :ash_form_builder, :theme, MyAppWeb.CustomTheme
```

### Creating Custom Themes

See `example_usage.ex` for a complete custom theme example.

---

## 🧪 Testing

Run the test suite:
```bash
mix test
```

---

## 🤝 Contributing

Contributions are welcome! This is an experimental project, and community feedback will help shape its development.

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

---

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- [Ash Framework](https://ash-hq.org/) - The excellent Elixir framework for building maintainable applications
- [Phoenix LiveView](https://hexdocs.pm/phoenix_live_view) - Real-time HTML without writing JavaScript
- [MishkaChelekom](https://github.com/mishka-group/mishka_chelekom) - UI component library

---

**Built with ❤️ using Ash Framework**
