# AshFormBuilder 🚀

[![Hex.pm](https://img.shields.io/hexpm/v/ash_form_builder.svg)](https://hex.pm/packages/ash_form_builder)
[![Hex.pm](https://img.shields.io/hexpm/dt/ash_form_builder.svg)](https://hex.pm/packages/ash_form_builder)
[![Hex.pm](https://img.shields.io/hexpm/l/ash_form_builder.svg)](https://hex.pm/packages/ash_form_builder)
[![Documentation](https://img.shields.io/badge/hex.pm-docs-green.svg)](https://hexdocs.pm/ash_form_builder)

**Latest Version:** [0.4.0](https://hex.pm/packages/ash_form_builder/0.4.0) | [Changelog](CHANGELOG.md)

> **What's new in 0.4.0**
> - 🎡 **iOS-style wheel datepicker** in the default theme (modal `<dialog>`, three or five scroll-snap wheels, no JS deps)
> - 📦 **First-class `:file_upload` DSL** — `accept :images`, `max_files 3`, `max_file_size {10, :mb}`, `cloud MyApp.Cloud`
> - 🪄 **Auto-generated `for_<action>/N`** for *every* declared form, not just `:create` / `:update`
> - 🏷️ **Tag combobox upserts on create** when the destination resource has an upsert action with an identity
> - 🎨 Polished default theme: per-field validation surfacing, animated nested-form add/remove, on/off toggle pill, chips below input

**AshFormBuilder = AshPhoenix.Form + Auto UI + Pluggable Themes + Full CRUD Generator**

A declarative form generation engine for [Ash Framework](https://hexdocs.pm/ash) and [Phoenix LiveView](https://hexdocs.pm/phoenix_live_view).

Define your form structure in a `forms do … end` block inside your Ash Resource and get a complete, policy-compliant LiveView form with:
- ✅ **One form per Ash action**, declared with `form :create do … end`
- ✅ **Per-form theming** — `theme :shadcn`, `accent :teal`, `transitions :smooth`
- ✅ **Pluggable theme registry** — short atoms (`:default`, `:shadcn`, `:glassmorphism`, `:mishka`) or your own
- ✅ Auto-inferred fields with smart defaults — booleans become **toggles**, many-to-many becomes a **checkbox group**
- ✅ Dynamic nested forms for `has_many` relationships (recursive, any depth)
- ✅ Searchable combobox available via `type :multiselect_combobox` for many-to-many when you want it
- ✅ **Full CRUD scaffold** — `mix ash_form.gen.live -r MyApp.Resource`
- ✅ Full Ash policy and validation enforcement, including atomic updates and changesets

---

## 🎯 The Pitch: Why AshFormBuilder?

| Layer | AshPhoenix.Form | AshFormBuilder |
|-------|----------------|----------------|
| **CRUD Scaffold** | ❌ Write it all yourself | ✅ **`mix ash_form.gen.live -r MyApp.Resource`** |
| **Data Table** | ❌ Build your own | ✅ **Cinder (filter, sort, paginate, URL sync)** |
| **Form State** | ✅ Provides `AshPhoenix.Form` | ✅ Uses `AshPhoenix.Form` |
| **Field Inference** | ❌ Manual field definition | ✅ **Auto-infers from action.accept** |
| **UI Components** | ❌ You render everything | ✅ **Smart components per field type** |
| **Themes** | ❌ No theming | ✅ **Pluggable theme system** |
| **Combobox** | ❌ Build your own | ✅ **Searchable + Creatable built-in** |
| **Nested Forms** | ❌ Manual setup | ✅ **Auto nested forms with add/remove** |
| **Lines of Code** | ~20-50 lines | **~1-3 lines** (or one command) |

**In short:** AshPhoenix.Form gives you the engine. AshFormBuilder gives you the complete car — factory-delivered.

---

## ⚡ Quick Start

### 1. Add to mix.exs

```elixir
{:ash_form_builder, "~> 0.4.0"}
```

### 2. (Optional) configure a theme

```elixir
# config/config.exs — short atom or module name
config :ash_form_builder, :theme, :default
# config :ash_form_builder, :theme, :shadcn
# config :ash_form_builder, :theme, AshFormBuilder.Themes.Glassmorphism
```

If you write your own themes, register them once and refer to them by short name from any form:

```elixir
config :ash_form_builder, :themes,
  my_brand: MyAppWeb.Themes.MyBrand,
  retro:    MyAppWeb.Themes.Retro
```

### 3. Add the extension and a `forms do … end` block

```elixir
defmodule MyApp.Todos.Task do
  use Ash.Resource,
    domain: MyApp.Todos,
    extensions: [AshFormBuilder]

  attributes do
    uuid_primary_key :id
    attribute :title,       :string,  allow_nil?: false, public?: true
    attribute :description, :string,                     public?: true
    attribute :completed,   :boolean, default: false,    public?: true
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [:title, :description, :completed]
    end

    update :update do
      accept [:title, :description, :completed]
    end
  end

  forms do
    form :create do
      submit_label "Create Task"
      accent       :teal
      transitions  :smooth

      field :title do
        label       "Task Title"
        placeholder "Enter task title"
        required    true
      end
    end

    form :update do
      submit_label "Update Task"
      accent       :indigo
    end
  end
end
```

The DSL accepts one `form :action do … end` entity per Ash action. Each form
keeps its own `submit_label`, `accent`, `transitions`, `theme`, fields and
nested blocks. Fields are auto-inferred from the action's `accept` list — only
declare a `field :title do … end` to override label/placeholder/required, etc.

### 4. Use in LiveView

```elixir
defmodule MyAppWeb.TaskLive.New do
  use MyAppWeb, :live_view

  def mount(_params, _session, socket) do
    form = MyApp.Todos.Task.Form.for_create(actor: socket.assigns.current_user)
    {:ok, assign(socket, form: form)}
  end

  def render(assigns) do
    ~H"""
    <.live_component
      module={AshFormBuilder.FormComponent}
      id="task-create-form"
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

`AshFormBuilder.FormComponent` reads the action from `form.source` and pulls
the right form config (theme, accent, transitions, fields, nested) from the
DSL. You can also override at render time by passing `theme={:shadcn}`,
`accent={:rose}`, or `transitions={:none}` directly to the live component.

### 5. Or scaffold the whole CRUD interface

```bash
mix ash_form.gen.live -r MyApp.Todos.Task --accent teal --transitions smooth
```

Generates a Phoenix LiveView (`index.ex`) and template (`index.html.heex`) with
`Cinder.collection` for the data table and the form modal pre-wired to call
`Task.Form.for_create/1` and `Task.Form.for_update/2`.

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

forms do
  form :create do
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
end
```

> Many-to-many relationships render as a `:checkbox_group` by default
> (vertical list of checkboxes). Set `type :multiselect_combobox`
> explicitly when you want the searchable / creatable combobox above.

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
forms do
  form :create do
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

forms do
  form :create do
    nested :subtasks do
      label "Subtasks"
      cardinality :many
      add_label "Add Subtask"
      remove_label "Remove"

      field :title do
        required true
      end

      field :done do
        type :toggle
      end
    end
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
      type           :file_upload
      label          "Profile Photo"
      hint           "JPEG or PNG, max 5 MB"

      accept         :images               # or ~w(.jpg .jpeg .png) — see table below
      max_files      1
      max_file_size  {5, :mb}              # also accepts a raw byte integer
      cloud          MyApp.Buckets.Cloud
    end
  end
end
```

### Upload DSL options (v0.4.0)

Upload options are now first-class DSL fields on `field` rather than
buried inside `opts: [upload: [...]]`. The legacy keyword shape is still
honoured, but first-class fields take precedence when both are set.

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `accept` | atom \| list \| string | `:any` | `:any`, a shorthand atom (`:images`, `:documents`, `:audio`, `:video`), or an explicit list (`~w(.jpg .png image/webp)`) |
| `max_files` | pos_integer | `1` | Maximum number of files (Phoenix `max_entries`) |
| `max_file_size` | pos_integer \| `{n, unit}` | `8_000_000` | Bytes, or `{10, :mb}` / `{500, :kb}` / `{1, :gb}` |
| `cloud` | module | nil | Optional `Buckets.Cloud` module — when omitted the upload is consumed in-process |
| `bucket` | string | nil | Optional bucket / prefix passed to the cloud module |
| `auto_upload` | boolean | `false` | Mirrors Phoenix LiveView's `auto_upload: true` |

**Shorthand `accept` values:**

| Atom | Expands to |
|------|------------|
| `:images` | `~w(.jpg .jpeg .png .gif .webp .svg)` |
| `:documents` | `~w(.pdf .doc .docx .txt .md .rtf)` |
| `:audio` | `~w(.mp3 .wav .ogg .m4a .flac)` |
| `:video` | `~w(.mp4 .mov .webm .avi .mkv)` |

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
  type           :file_upload
  label          "Attachments"
  hint           "Upload multiple documents (max 5)"

  accept         :documents
  max_files      5
  max_file_size  {10, :mb}
  cloud          MyApp.Buckets.Cloud
end
```

### Custom action helpers (v0.4.0)

Each declared `form :action do … end` block generates a matching
`Resource.Form.for_<action>/N` helper — including for **custom action
names**, not just `:create` / `:update`. Record-shaped actions
(`:update`, `:destroy`) take the record as the first argument.

```elixir
actions do
  create  :create do …
  update  :update do …
  update  :archive, accept: [] do …
  update  :publish, accept: [:published_at] do …
end

forms do
  form :create  do … end
  form :update  do … end
  form :archive do submit_label "Archive" end
  form :publish do submit_label "Publish now" end
end
```

```elixir
# Auto-generated:
MyApp.Posts.Post.Form.for_create()                      # :create  (resource form)
MyApp.Posts.Post.Form.for_update(post)                  # :update  (record form)
MyApp.Posts.Post.Form.for_archive(post, actor: user)    # :archive (record form)
MyApp.Posts.Post.Form.for_publish(post, actor: user)    # :publish (record form)

# Plus the generic fallback for anything else:
MyApp.Posts.Post.Form.for_action(:custom, record: post, actor: user)
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
- [**Readme**](https://hexdocs.pm/ash_form_builder/readme.html) - Getting started guide
- [**Changelog**](https://hexdocs.pm/ash_form_builder/changelog.html) - Version history and migration notes

### Guides

- [**Theme Customization Guide**](https://hexdocs.pm/ash_form_builder/theme_customization_guide.html) - Create custom themes
- [**Todo App Tutorial**](https://hexdocs.pm/ash_form_builder/todo_app_integration.html) - Step-by-step integration
- [**Relationships Guide**](https://hexdocs.pm/ash_form_builder/relationships_guide.html) - has_many vs many_to_many
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
       {:ash_form_builder, "~> 0.3.0"},

       # Required if using mix ash_form_builder.gen.live
       {:cinder, "~> 0.12"},

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

## 🚀 Magic Generators (New in v0.3.0)

One command. Full CRUD. Production-grade LiveView in seconds.

```bash
mix ash_form_builder.gen.live Accounts User
```

That's it. The generator outputs two ready-to-use files wired with **Cinder** for the data table and **AshFormBuilder** inside a Phoenix modal for create/edit — no boilerplate to write.

### What Gets Generated

| File | Contents |
|------|----------|
| `lib/my_app_web/live/user_live/index.ex` | Full LiveView: `mount`, `handle_params`, `handle_info`, `handle_event` |
| `lib/my_app_web/live/user_live/index.html.heex` | HEEx template: Cinder table + modal with `AshFormBuilder.FormComponent` |

### Generated `index.ex` — the LiveView

```elixir
defmodule MyAppWeb.UserLive.Index do
  use MyAppWeb, :live_view
  use Cinder.UrlSync         # injects handle_info for URL sync automatically

  alias MyApp.Accounts.User

  @collection_id "user-collection"

  def mount(_params, _session, socket) do
    {:ok, assign(socket, url_state: false, record: nil, form: nil)}
  end

  def handle_params(params, uri, socket) do
    socket = Cinder.UrlSync.handle_params(params, uri, socket)
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  # Triggered by AshFormBuilder.FormComponent after a successful Ash action
  def handle_info({:form_submitted, User, _result}, socket) do
    {:noreply,
     socket
     |> put_flash(:info, "User saved successfully.")
     |> Cinder.refresh_table(@collection_id)   # async re-query, no page reload
     |> push_patch(to: ~p"/users")}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    User |> Ash.get!(id, actor: socket.assigns[:current_user])
         |> Ash.destroy!(actor: socket.assigns[:current_user])
    {:noreply, socket |> put_flash(:info, "User deleted.") |> Cinder.refresh_table(@collection_id)}
  end
end
```

**Every callback is fully wired:**

| Callback | Behaviour |
|----------|-----------|
| `mount/3` | Initialises `url_state`, `record`, `form` assigns |
| `handle_params/3` | Delegates to `Cinder.UrlSync`; routes `:new` / `:edit` live actions |
| `apply_action :new` | Builds `AshPhoenix.Form.for_create` |
| `apply_action :edit` | `Ash.get!` + `AshPhoenix.Form.for_update` |
| `handle_info :form_submitted` | Flash + `Cinder.refresh_table` + `push_patch` to index |
| `handle_event "delete"` | `Ash.get!` + `Ash.destroy!` + `Cinder.refresh_table` |

### Generated `index.html.heex` — the template

```heex
<.header>
  Users
  <:actions>
    <.link patch={~p"/users/new"}><.button>New User</.button></.link>
  </:actions>
</.header>

<%!-- Cinder.collection: filterable, sortable, paginated — state synced to URL --%>
<Cinder.collection
  id="user-collection"
  resource={MyApp.Accounts.User}
  actor={assigns[:current_user]}
  url_state={@url_state}
  page_size={25}
  empty_message="No users found."
>
  <%!-- TODO: Replace with your resource's real attributes (see Customising Columns) --%>
  <:col :let={user} field="id" sort label="ID">{user.id}</:col>

  <:col :let={user} label="Actions">
    <.link patch={~p"/users/#{user}/edit"}>Edit</.link>
    <.link phx-click="delete" phx-value-id={user.id}
           data-confirm="Delete this user? This cannot be undone.">Delete</.link>
  </:col>
</Cinder.collection>

<%!-- Modal: mounts only for :new and :edit live_actions --%>
<.modal :if={@live_action in [:new, :edit]} id="user-modal" show
        on_cancel={JS.patch(~p"/users")}>
  <.live_component
    module={AshFormBuilder.FormComponent}
    id={if @record, do: "user-edit-#{@record.id}", else: "user-new"}
    resource={MyApp.Accounts.User}
    form={@form}
    submit_label={if @live_action == :new, do: "Create User", else: "Save Changes"}
  />
</.modal>
```

### Router Entries (printed by the generator)

```elixir
scope "/", MyAppWeb do
  pipe_through :browser

  live "/users",          UserLive.Index, :index
  live "/users/new",      UserLive.Index, :new
  live "/users/:id/edit", UserLive.Index, :edit
end
```

### Generator Options

| Option | Default | Description |
|--------|---------|-------------|
| `--page-size` / `-p` | `25` | Rows per page in the Cinder table |
| `--out` / `-o` | `lib/<app>_web/live/<resource>_live` | Output directory override |

```bash
mix ash_form_builder.gen.live Inventory Product --page-size 50
mix ash_form_builder.gen.live Accounts User --out lib/my_app_web/live/admin
```

### Customising Columns

After generation, open `index.html.heex` and replace the placeholder `<:col>` slots with your resource's real attributes:

```heex
<:col :let={user} field="name"        filter sort>{user.name}</:col>
<:col :let={user} field="email"       filter>{user.email}</:col>
<:col :let={user} field="role"        filter={:select}>{user.role}</:col>
<:col :let={user} field="inserted_at" sort>{user.inserted_at}</:col>
```

Cinder column attributes:
- `filter` — text filter input for that column
- `filter={:select}` — dropdown filter for enum/atom fields
- `sort` — enables column sort toggle
- `search` — includes field in the global search bar (if configured)

### Prerequisites

The generator requires [Cinder](https://hex.pm/packages/cinder) for the data table. Add it to your `mix.exs`:

```elixir
{:cinder, "~> 0.12"}
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

**v0.3.0 - Production-Ready**

This version includes:
- ✅ Full CRUD LiveView generator (`mix ash_form_builder.gen.live`)
- ✅ Deep Cinder integration (data table, URL sync, async refresh)
- ✅ Zero-config field inference
- ✅ Searchable/creatable combobox
- ✅ Dynamic nested forms
- ✅ Glassmorphism, Shadcn, Default, and MishkaChelekom themes
- ✅ Full Ash policy enforcement
- ✅ 180 tests, 0 failures
- ✅ Clean `mix credo --strict` and `mix dialyzer`

**Known Limitations:**
- Deeply nested forms (3+ levels) require manual path handling
- i18n support planned for a future release
- Field-level permissions planned for a future release

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
