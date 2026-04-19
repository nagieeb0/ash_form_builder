# AshFormBuilder 🚀

[![Hex.pm](https://img.shields.io/hexpm/v/ash_form_builder.svg)](https://hex.pm/packages/ash_form_builder)
[![Hex.pm](https://img.shields.io/hexpm/dt/ash_form_builder.svg)](https://hex.pm/packages/ash_form_builder)
[![Hex.pm](https://img.shields.io/hexpm/l/ash_form_builder.svg)](https://hex.pm/packages/ash_form_builder)
[![Documentation](https://img.shields.io/badge/hex.pm-docs-green.svg)](https://hexdocs.pm/ash_form_builder)

**AshFormBuilder = AshPhoenix.Form + Auto UI + Smart Components + Themes**

A declarative form generation engine for [Ash Framework](https://hexdocs.pm/ash) and [Phoenix LiveView](https://hexdocs.pm/phoenix_live_view).

Define your form structure in **1-3 lines** inside your Ash Resource, and get a complete, policy-compliant LiveView form with:
- ✅ Auto-inferred fields from your action's `accept` list
- ✅ Searchable combobox for many-to-many relationships
- ✅ Creatable combobox (create related records on-the-fly)
- ✅ Dynamic nested forms for has_many relationships
- ✅ Pluggable theme system (Default, MishkaChelekom, or custom)
- ✅ Full Ash policy and validation enforcement

---

## 🎯 The Pitch: Why AshFormBuilder?

| Layer | AshPhoenix.Form | AshFormBuilder |
|-------|----------------|----------------|
| **Form State** | ✅ Provides `AshPhoenix.Form` | ✅ Uses `AshPhoenix.Form` |
| **Field Inference** | ❌ Manual field definition | ✅ **Auto-infers from action.accept** |
| **UI Components** | ❌ You render everything | ✅ **Smart components per field type** |
| **Themes** | ❌ No theming | ✅ **Pluggable theme system** |
| **Combobox** | ❌ Build your own | ✅ **Searchable + Creatable built-in** |
| **Nested Forms** | ❌ Manual setup | ✅ **Auto nested forms with add/remove** |
| **Lines of Code** | ~20-50 lines | **~1-3 lines** |

**In short:** AshPhoenix.Form gives you the engine. AshFormBuilder gives you the complete car.

---

## ⚡ 3-Line Quick Start

### 1. Add to mix.exs

```elixir
{:ash_form_builder, "~> 0.2.0"}
```

### 2. Configure Theme (config/config.exs)

```elixir
config :ash_form_builder, :theme, AshFormBuilder.Themes.Default
```

### 3. Add Extension to Resource

```elixir
defmodule MyApp.Todos.Task do
  use Ash.Resource,
    domain: MyApp.Todos,
    extensions: [AshFormBuilder]  # ← Add this

  attributes do
    uuid_primary_key :id
    attribute :title, :string, allow_nil?: false
    attribute :description, :text
    attribute :completed, :boolean, default: false
  end

  actions do
    create :create do
      accept [:title, :description, :completed]
    end
  end

  form do
    action :create  # ← That's it! Fields auto-inferred
  end
end
```

### 4. Use in LiveView

```elixir
defmodule MyAppWeb.TaskLive.Form do
  use MyAppWeb, :live_view

  def mount(_params, _session, socket) do
    form = MyApp.Todos.Task.Form.for_create(actor: socket.assigns.current_user)
    {:ok, assign(socket, form: form)}
  end

  def render(assigns) do
    ~H"""
    <.live_component
      module={AshFormBuilder.FormComponent}
      id="task-form"
      resource={MyApp.Todos.Task}
      form={@form}
    />
    """
  end

  def handle_info({:form_submitted, MyApp.Todos.Task, task}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/tasks/#{task.id}")}
  end
end
```

**Result:** A complete, validated form with title (text input), description (textarea), and completed (checkbox) - all from 1 line of configuration.

---

## ✨ Key Features

### 🔍 Searchable Many-to-Many Combobox

Automatically renders searchable multi-select for relationships:

```elixir
relationships do
  many_to_many :tags, MyApp.Todos.Tag do
    through MyApp.Todos.TaskTag
  end
end

actions do
  create :create do
    accept [:title]
    manage_relationship :tags, :tags, type: :append_and_remove
  end
end

form do
  action :create
  
  field :tags do
    type :multiselect_combobox
    opts [
      search_event: "search_tags",
      debounce: 300,
      label_key: :name,
      value_key: :id
    ]
  end
end
```

**LiveView Search Handler:**

```elixir
def handle_event("search_tags", %{"query" => query}, socket) do
  tags = MyApp.Todos.Tag
           |> Ash.Query.filter(contains(name: ^query))
           |> MyApp.Todos.read!()
  
  {:noreply, push_event(socket, "update_combobox_options", %{
    field: "tags",
    options: Enum.map(tags, &{&1.name, &1.id})
  })}
end
```

### ✨ Creatable Combobox (Create On-the-Fly)

Allow users to create new related records without leaving the form:

```elixir
form do
  field :tags do
    type :multiselect_combobox
    opts [
      creatable: true,              # ← Enable creating
      create_action: :create,
      create_label: "Create \"",
      search_event: "search_tags"
    ]
  end
end
```

**What happens:**
1. User types "Urgent" in combobox
2. No results found → "Create 'Urgent'" button appears
3. Click → Creates new Tag record via Ash
4. New tag automatically added to selection
5. All Ash validations and policies enforced

### 🔗 Dynamic Nested Forms (has_many)

Manage child records with dynamic add/remove:

```elixir
relationships do
  has_many :subtasks, MyApp.Todos.Subtask
end

form do
  nested :subtasks do
    label "Subtasks"
    cardinality :many
    add_label "Add Subtask"
    remove_label "Remove"
    
    field :title, required: true
    field :completed, type: :checkbox
  end
end
```

**Renders:**
- Fieldset with "Subtasks" legend
- Existing subtasks rendered with all fields
- "Add Subtask" button → adds new subtask form
- "Remove" button on each subtask → removes from form
- Full validation support for nested fields

---

## 🎨 Theme System

### Built-in Themes

```elixir
# Default theme (semantic HTML, no dependencies)
config :ash_form_builder, :theme, AshFormBuilder.Themes.Default

# MishkaChelekom theme (requires mishka_chelekom dependency)
config :ash_form_builder, :theme, AshFormBuilder.Theme.MishkaTheme
```

### Custom Theme Example

```elixir
defmodule MyAppWeb.CustomTheme do
  @behaviour AshFormBuilder.Theme
  use Phoenix.Component

  @impl AshFormBuilder.Theme
  def render_field(assigns, opts) do
    case assigns.field.type do
      :text_input -> render_text_input(assigns)
      :multiselect_combobox -> render_combobox(assigns)
      # ... etc
    end
  end

  defp render_text_input(assigns) do
    ~H"""
    <div class="form-group">
      <label for={Phoenix.HTML.Form.input_id(@form, @field.name)}>
        {@field.label}
      </label>
      <input
        type="text"
        id={Phoenix.HTML.Form.input_id(@form, @field.name)}
        class="form-control"
      />
    </div>
    """
  end
end
```

---

## 📚 Documentation

- [**Installation Guide**](https://hexdocs.pm/ash_form_builder) - Complete setup instructions
- [**Todo App Tutorial**](guides/todo_app_integration.exs) - Step-by-step integration guide
- [**Relationships Guide**](guides/relationships_guide.exs) - has_many vs many_to_many deep dive
- [**API Reference**](https://hexdocs.pm/ash_form_builder/api-reference.html) - Complete module docs

---

## 📦 Installation

### Requirements

- Elixir ~> 1.17
- Phoenix ~> 1.7
- Phoenix LiveView ~> 1.0
- Ash ~> 3.0
- AshPhoenix ~> 2.0

### Steps

1. **Add dependency** to `mix.exs`:

   ```elixir
   defp deps do
     [
       {:ash, "~> 3.0"},
       {:ash_phoenix, "~> 2.0"},
       {:ash_form_builder, "~> 0.2.0"},
       
       # Optional: For MishkaChelekom theme
       {:mishka_chelekom, "~> 0.0.8"}
     ]
   end
   ```

2. **Fetch dependencies**:

   ```bash
   mix deps.get
   ```

3. **Configure theme** in `config/config.exs`:

   ```elixir
   config :ash_form_builder, :theme, AshFormBuilder.Themes.Default
   ```

4. **Add extension** to your Ash Resource:

   ```elixir
   use Ash.Resource,
     domain: MyApp.Todos,
     extensions: [AshFormBuilder]
   ```

---

## 🔧 Field Type Inference

AshFormBuilder automatically maps Ash types to UI components:

| Ash Type | Constraint | UI Type | Example |
|----------|------------|---------|---------|
| `:string` | - | `:text_input` | Text fields |
| `:text` | - | `:textarea` | Multi-line text |
| `:boolean` | - | `:checkbox` | Toggle switches |
| `:integer` / `:float` | - | `:number` | Numeric inputs |
| `:date` | - | `:date` | Date picker |
| `:datetime` | - | `:datetime` | DateTime picker |
| `:atom` | `one_of:` | `:select` | Dropdown |
| `:enum` module | - | `:select` | Enum dropdown |
| `many_to_many` | - | `:multiselect_combobox` | Searchable multi-select |
| `has_many` | - | `:nested_form` | Dynamic nested forms |

---

## 🧪 Testing

```elixir
defmodule MyAppWeb.TaskLiveTest do
  use MyAppWeb.ConnCase

  import Phoenix.LiveViewTest

  test "renders form with auto-inferred fields", %{conn: conn} do
    {:ok, _view, html} = live_isolated(conn, MyAppWeb.TaskLive.Form)
    
    assert html =~ "Task Title"
    assert html =~ "Description"
    assert html =~ "Completed"
  end

  test "creates task and redirects", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, MyAppWeb.TaskLive.Form)
    
    assert form(view, "#task-form", task: %{
      title: "Test Task",
      description: "Test description"
    }) |> render_submit()
    
    assert_redirect(view, ~p"/tasks/*")
  end
end
```

---

## ⚠️ Version Status

**v0.2.0 - Production-Ready Beta**

This version includes:
- ✅ Zero-config field inference
- ✅ Searchable/creatable combobox
- ✅ Dynamic nested forms
- ✅ Pluggable theme system
- ✅ Full Ash policy enforcement
- ✅ Comprehensive test suite

**Known Limitations:**
- Deeply nested forms (3+ levels) require manual path handling
- i18n support planned for v0.3.0
- Field-level permissions planned for v0.3.0

---

## 🤝 Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Add tests
5. Run `mix test` and `mix format`
6. Submit a pull request

### Development Setup

```bash
git clone https://github.com/nagieeb0/ash_form_builder.git
cd ash_form_builder
mix deps.get
mix test
```

---

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- [Ash Framework](https://hexdocs.pm/ash) - The excellent Elixir framework
- [Phoenix LiveView](https://hexdocs.pm/phoenix_live_view) - Real-time HTML without JavaScript
- [MishkaChelekom](https://github.com/mishka-group/mishka_chelekom) - UI component library

---

**Built with ❤️ using Ash Framework and Phoenix LiveView**
