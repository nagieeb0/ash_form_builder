# AshFormBuilder 🚀

[![Hex.pm](https://img.shields.io/hexpm/v/ash_form_builder.svg)](https://hex.pm/packages/ash_form_builder)
[![Hex.pm](https://img.shields.io/hexpm/dt/ash_form_builder.svg)](https://hex.pm/packages/ash_form_builder)
[![Hex.pm](https://img.shields.io/hexpm/l/ash_form_builder.svg)](https://hex.pm/packages/ash_form_builder)
[![Documentation](https://img.shields.io/badge/hex.pm-docs-green.svg)](https://hexdocs.pm/ash_form_builder)

**Latest Version:** [0.2.3](https://hex.pm/packages/ash_form_builder/0.2.3) | [Changelog](CHANGELOG.md)

**AshFormBuilder = AshPhoenix.Form + Auto UI + Smart Components + Themes**

A declarative form generation engine for [Ash Framework](https://hexdocs.pm/ash) and [Phoenix LiveView](https://hexdocs.pm/phoenix_live_view).

Define your form structure in **1-3 lines** inside your Ash Resource, and get a complete, policy-compliant LiveView form with:
- ✅ Auto-inferred fields from your action's `accept` list
- ✅ Searchable combobox for many-to-many relationships
- ✅ Creatable combobox (create related records on-the-fly)
- ✅ Dynamic nested forms for has_many relationships
- ✅ Pluggable theme system (Default, Glassmorphism, Shadcn, MishkaChelekom, or custom)
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
{:ash_form_builder, "~> 0.2.3"}
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
    defaults [:create, :read, :update, :destroy]
  end

  # Create form - auto-infers fields from :create action
  form do
    action :create  # ← That's it! Fields auto-inferred
    submit_label "Create Task"
  end

  # Update form - separate configuration for update action
  form do
    action :update
    submit_label "Update Task"
  end
end
```

### 4. Use in LiveView

**Create Form:**

```elixir
defmodule MyAppWeb.TaskLive.Form do
  use MyAppWeb, :live_view

  def mount(_params, _session, socket) do
    form = MyApp.Todos.Task.Form.for_create(actor: socket.assigns.current_user)
    {:ok, assign(socket, form: form, mode: :create)}
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

**Update Form:**

```elixir
defmodule MyAppWeb.TaskLive.Edit do
  use MyAppWeb, :live_view

  def mount(%{"id" => id}, _session, socket) do
    task = MyApp.Todos.get_task!(id, actor: socket.assigns.current_user)
    form = MyApp.Todos.Task.Form.for_update(task, actor: socket.assigns.current_user)
    {:ok, assign(socket, form: form, mode: :edit)}
  end

  def render(assigns) do
    ~H"""
    <.live_component
      module={AshFormBuilder.FormComponent}
      id="task-edit-form"
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

**Result:** Complete create and update forms with auto-inferred fields - all from 2 `form` blocks.

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

## 📁 File Uploads

AshFormBuilder provides declarative file upload support that bridges Phoenix LiveView's native upload lifecycle with Ash Framework's file handling.

### Basic File Upload

```elixir
defmodule MyApp.Users.User do
  use Ash.Resource,
    domain: MyApp.Users,
    extensions: [AshFormBuilder]

  attributes do
    uuid_primary_key :id
    attribute :name, :string, allow_nil?: false
    attribute :avatar_path, :string
  end

  actions do
    create :create do
      accept [:name]
      argument :avatar, :string, allow_nil?: true
      
      # Store the uploaded file path in the avatar_path attribute
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

    field :avatar do
      type :file_upload
      label "Profile Photo"
      hint "JPEG or PNG, max 5 MB"
      
      opts upload: [
        cloud: MyApp.Buckets.Cloud,      # Buckets.Cloud module for storage
        max_entries: 1,                   # Allow only 1 file
        max_file_size: 5_000_000,         # 5 MB max
        accept: ~w(.jpg .jpeg .png)       # Accepted file types
      ]
    end
  end
end
```

### Upload Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `cloud` | module | required | Module implementing `Buckets.Cloud` behaviour |
| `max_entries` | integer | 1 | Maximum number of files allowed |
| `max_file_size` | integer | 8_000_000 | Maximum file size in bytes |
| `accept` | list | `:any` | Accepted file extensions or MIME types |
| `bucket_name` | atom | nil | Optional bucket name for storage |

### How It Works

1. **Mount**: FormComponent automatically calls `allow_upload/3` for each `:file_upload` field
2. **Upload**: User selects file → Phoenix LiveView handles the upload progress
3. **Submit**: On form submission:
   - `consume_uploaded_entries/3` is called for each upload field
   - Files are stored via the configured `Buckets.Cloud` module
   - Final file paths are injected into Ash action parameters
   - Ash action receives the stored file paths

### Multiple File Uploads

```elixir
field :attachments do
  type :file_upload
  label "Attachments"
  hint "Upload multiple documents (max 5)"
  
  opts upload: [
    cloud: MyApp.Buckets.Cloud,
    max_entries: 5,
    max_file_size: 10_000_000,
    accept: ~w(.pdf .doc .docx)
  ]
end
```

### Using in LiveView

```elixir
defmodule MyAppWeb.UserLive.Create do
  use MyAppWeb, :live_view

  def mount(_params, _session, socket) do
    form = MyApp.Users.User.Form.for_create(actor: socket.assigns.current_user)
    {:ok, assign(socket, form: form)}
  end

  def render(assigns) do
    ~H"""
    <.live_component
      module={AshFormBuilder.FormComponent}
      id="user-form"
      resource={MyApp.Users.User}
      form={@form}
    />
    """
  end

  def handle_info({:form_submitted, MyApp.Users.User, user}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/users/#{user.id}")}
  end
end
```

### Theme Support

File uploads are styled according to your configured theme:
- **Default Theme**: Clean HTML5 file input with progress bar
- **MishkaTheme**: Styled with Tailwind CSS, includes image previews
- **Custom Themes**: Implement `render_file_upload/1` in your theme module

---

## 🔄 Create vs Update Forms

AshFormBuilder supports both create and update forms with **separate `form` blocks** for each action.

### Multiple Form Blocks Per Resource

You can define multiple `form` blocks in the same resource - each targeting a different action:

```elixir
defmodule MyApp.Todos.Task do
  use Ash.Resource,
    domain: MyApp.Todos,
    extensions: [AshFormBuilder]

  # ... attributes and relationships

  actions do
    defaults [:create, :read, :update, :destroy]
  end

  # CREATE form configuration
  form do
    action :create
    submit_label "Create Task"

    field :title do
      label "Task Title"
      placeholder "Enter task title"
      required true
    end
  end

  # UPDATE form configuration (separate block)
  form do
    action :update
    submit_label "Save Changes"

    # Can have different field customizations for update
    field :title do
      label "Task Title"
      hint "Changing the title will notify collaborators"
    end
  end
end
```

### Update Forms Auto-Preload Relationships

For update forms, `many_to_many` relationships are **automatically preloaded** so the form displays existing selections:

```elixir
# In your LiveView
def mount(%{"id" => id}, _session, socket) do
  # for_update/2 automatically preloads required relationships
  task = MyApp.Todos.Task |> MyApp.Todos.get_task!(id)
  form = MyApp.Todos.Task.Form.for_update(task, actor: socket.assigns.current_user)
  {:ok, assign(socket, form: form)}
end
```

**Behind the scenes:** The generated `Form.for_update/2` helper detects which relationships need preloading (based on your `many_to_many` fields) and loads them automatically.

### Domain Code Interface with Update Forms

When using Domain Code Interfaces, update forms work seamlessly:

```elixir
# Domain configuration
defmodule MyApp.Todos do
  use Ash.Domain

  resources do
    resource MyApp.Todos.Task do
      define :form_to_create_task, action: :create
      define :form_to_update_task, action: :update  # ← Update form helper
    end
  end
end

# LiveView usage
form = MyApp.Todos.form_to_update_task(task, actor: current_user)
```

---

## 🎨 Theme System

### Built-in Themes

#### AshFormBuilder.Themes.Default (Recommended)
Production-ready Tailwind CSS styling with zero configuration.

```elixir
config :ash_form_builder, :theme, AshFormBuilder.Themes.Default
```

#### AshFormBuilder.Themes.Glassmorphism (New in 0.2.3)
Premium glass-effect UI with backdrop blur, smooth animations, and dark mode.

```elixir
config :ash_form_builder, :theme, AshFormBuilder.Themes.Glassmorphism
```

#### AshFormBuilder.Themes.Shadcn (New in 0.2.3)
Clean, minimal design inspired by shadcn/ui with crisp borders and focus rings.

```elixir
config :ash_form_builder, :theme, AshFormBuilder.Themes.Shadcn
```

#### AshFormBuilder.Theme.MishkaTheme
MishkaChelekom component integration (requires `mishka_chelekom` dependency).

```elixir
config :ash_form_builder, :theme, AshFormBuilder.Theme.MishkaTheme
```

### Custom Themes

Create your own theme by implementing the `AshFormBuilder.Theme` behaviour. See the [Theme Customization Guide](guides/theme_customization_guide.md) for a complete tutorial with examples for Tailwind, Bootstrap, and more.

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

### Core Documentation

- [**Hex Docs**](https://hexdocs.pm/ash_form_builder) - Complete API reference
- [**Changelog**](https://hexdocs.pm/ash_form_builder/changelog.html) - Version history and migration notes

### Guides

- [**Theme Customization Guide**](https://hexdocs.pm/ash_form_builder/guides/theme_customization_guide.html) - Create custom themes
- [**Todo App Tutorial**](https://hexdocs.pm/ash_form_builder/guides/todo_app_integration.html) - Step-by-step integration
- [**Relationships Guide**](https://hexdocs.pm/ash_form_builder/guides/relationships_guide.html) - has_many vs many_to_many
- [**File Upload Guide**](https://hexdocs.pm/ash_form_builder/file_upload_guide.html) - File upload configuration
- [**Storage Configuration**](https://hexdocs.pm/ash_form_builder/storage_configuration.html) - S3, GCS, and local storage

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
       {:ash_form_builder, "~> 0.2.3"},
       
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
