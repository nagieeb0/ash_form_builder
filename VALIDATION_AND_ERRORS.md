# Validation, Error Handling & Form Lifecycle

## Overview

AshFormBuilder **encapsulates** all validation and error handling logic inside the `FormComponent`. You don't need to write any validation code manually - it's all handled automatically by leveraging `AshPhoenix.Form`.

---

## How Validation Works

### 1. **Live Validation** (on user input)

When a user types in a field and triggers validation (via `phx-change`), this happens:

```elixir
# lib/ash_form_builder/form_component.ex
@impl Phoenix.LiveComponent
def handle_event("validate", %{"form" => params}, socket) do
  # Delegates to AshPhoenix.Form.validate/2
  form = AshPhoenix.Form.validate(socket.assigns.form.source, params)
  {:noreply, assign(socket, form: to_form(form))}
end
```

**What happens:**
1. User types in field → triggers `phx-change="validate"`
2. FormComponent receives params
3. Calls `AshPhoenix.Form.validate/2` with new params
4. Ash runs all validations defined in your resource
5. Form re-renders with errors displayed

**Example:**
```elixir
# Your Ash Resource
defmodule MyApp.Users.User do
  use Ash.Resource, ...

  attributes do
    attribute :email, :string do
      allow_nil? false
      validations [
        string_length: [min: 5, max: 100],
        match: [~r/@/, message: "must be a valid email"]
      ]
    end
  end

  policies do
    policy action_type(:create) do
      authorize_if actor_present()
    end
  end
end

# In LiveView - NO validation code needed!
<.live_component
  module={AshFormBuilder.FormComponent}
  form={@form}
  resource={MyApp.Users.User}
/>
```

**Result:**
- ✅ Email required validation runs automatically
- ✅ Length validation runs automatically  
- ✅ Format validation runs automatically
- ✅ Policy checks run automatically
- ✅ Errors displayed in UI automatically

---

### 2. **Submit Validation** (on form submission)

When user clicks submit:

```elixir
@impl Phoenix.LiveComponent
def handle_event("submit", %{"form" => params}, socket) do
  # 1. Handle file uploads first
  {upload_params, socket} = consume_file_uploads(socket, file_fields, params)
  merged_params = Map.merge(params, upload_params)

  # 2. Submit to Ash (includes validation)
  case AshPhoenix.Form.submit(socket.assigns.form.source, params: merged_params) do
    {:ok, result} ->
      # Success - notify parent
      notify_parent(socket, result)
      {:noreply, socket}

    {:error, form} ->
      # Validation failed - re-render with errors
      {:noreply, assign(socket, form: to_form(form))}
  end
end
```

**What happens:**
1. User clicks submit
2. File uploads consumed (if any)
3. `AshPhoenix.Form.submit/2` called
4. Ash runs **all validations** + **policies** + **changes**
5. If valid → record created/updated → success
6. If invalid → form re-rendered with errors

---

## How Errors Are Displayed

### Error Extraction

Each theme extracts errors from the form:

```elixir
# lib/ash_form_builder/theme/mishka_theme.ex
defp extract_field_errors(form, field_name) do
  case form[field_name] do
    nil -> []
    field -> field.errors || []
  end
end
```

### Error Rendering (MishkaTheme Example)

```elixir
defp render_text_input(assigns) do
  assigns = Map.put(assigns, :field_errors, extract_field_errors(assigns.form, assigns.field.name))

  ~H"""
  <.text_field
    field={@form[@field.name]}
    label={@field.label}
    errors={@field_errors}  ← Passed to component
    ...
  />
  """
end
```

**In the UI:**
```html
<div class="form-group">
  <label>Email</label>
  <input type="email" class="input-error" />
  
  <!-- Errors displayed below field -->
  <p class="text-red-600">can't be blank</p>
  <p class="text-red-600">must be a valid email</p>
</div>
```

---

## File Upload Validation

File uploads have **additional validation** layers:

### 1. **Client-Side Validation** (Phoenix LiveView)

```elixir
field :avatar do
  type :file_upload
  opts upload: [
    max_entries: 1,        ← Validated by LiveView
    max_file_size: 5_000_000,  ← Validated by LiveView
    accept: ~w(.jpg .png)  ← Validated by LiveView
  ]
end
```

**Errors handled automatically:**
- `:too_large` - File exceeds max_file_size
- `:too_many_files` - More files than max_entries
- `:not_accepted` - File type not in accept list

### 2. **Server-Side Validation** (Your Ash Resource)

```elixir
actions do
  create :create do
    accept [:name]
    argument :avatar, :string, allow_nil?: true
    
    # Custom validation for file uploads
    validate present([:avatar_path], at_least: 1)
  end
end
```

### 3. **Storage Validation** (Buckets.Cloud)

```elixir
defp consume_file_uploads(socket, file_fields, params) do
  result = Phoenix.LiveView.consume_uploaded_entries(...)
  
  # Filter errors
  successful_paths = Enum.filter(result, &(elem(&1, 0) == :ok))
  error_paths = Enum.filter(result, &(elem(&1, 0) == :postpone))
  
  # Log storage errors
  Enum.each(error_paths, fn {:postpone, reason} ->
    Logger.error("Upload postponed: #{inspect(reason)}")
  end)
end
```

---

## Error Types & Handling

### 1. **Validation Errors** (Ash.Changeset)

**Source:** Ash resource validations

```elixir
# Resource
validations do
  validate present(:name)
  validate string_length(:name, min: 3, max: 100)
end

# Error displayed to user:
"can't be blank"
"must be between 3 and 100 characters"
```

### 2. **Policy Errors** (Ash.Policy)

**Source:** Ash authorization policies

```elixir
# Resource
policies do
  policy action_type(:create) do
    authorize_if actor_present()
  end
end

# Error (not shown to user, logged):
"Autorization failed: actor not present"
```

### 3. **Relationship Errors**

**Source:** Nested form validation

```elixir
# Parent form with nested tasks
nested :tasks do
  field :title, required: true
end

# Error displayed:
"tasks[0].title: can't be blank"
```

### 4. **File Upload Errors**

**Source:** Phoenix LiveView + Storage

```elixir
# Displayed in UI:
"File is too large"
"Too many files selected"
"File type not accepted"
"Upload storage failed: permission denied"
```

---

## Form Lifecycle Complete Flow

```
┌─────────────────────────────────────────────────────────────┐
│ 1. MOUNT                                                    │
│    - FormComponent.update/2 called                          │
│    - AshPhoenix.Form created via Resource.Form.for_create  │
│    - File uploads allowed (allow_upload/3)                  │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 2. USER INPUT (Live Validation)                             │
│    - handle_event("validate", params)                       │
│    - AshPhoenix.Form.validate/2 called                      │
│    - Ash validations run                                    │
│    - Form re-renders with errors (if any)                   │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 3. FILE UPLOAD                                              │
│    - User selects file                                      │
│    - LiveView handles chunked upload                        │
│    - Progress displayed                                     │
│    - Client-side validation (size, type, count)             │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 4. SUBMIT                                                   │
│    - handle_event("submit", params)                         │
│    - consume_uploaded_entries/3 called                      │
│    - Files stored via Buckets.Cloud                         │
│    - Paths merged into params                               │
│    - AshPhoenix.Form.submit/2 called                        │
└─────────────────────────────────────────────────────────────┘
                           ↓
              ┌────────────┴────────────┐
              ↓                         ↓
     ┌─────────────────┐      ┌─────────────────┐
     │ SUCCESS         │      │ ERROR           │
     │                 │      │                 │
     │ - Ash action    │      │ - Validations   │
     │   runs          │      │   failed        │
     │ - Record saved  │      │ - Policies      │
     │ - notify_parent │      │   failed        │
     │ - Flash message │      │ - Form re-      │
     │ - Redirect/     │      │   rendered      │
     │   navigate      │      │ - Errors shown  │
     └─────────────────┘      └─────────────────┘
```

---

## Custom Validation Handling

### Adding Custom Validations

```elixir
defmodule MyApp.Users.User do
  use Ash.Resource, ...

  actions do
    create :create do
      accept [:email, :age]
      
      # Custom validation
      validate {MyApp.Validations, :adult_user, fields: [:age]}
      
      # Conditional validation
      validate present(:phone), if: [present(:contact_by_phone)]
    end
  end
end
```

**Result:** Automatically run on form submit, errors displayed in UI.

### Custom Error Messages

```elixir
validations do
  validate string_length(:password, min: 8, 
    message: "Password must be at least 8 characters long"
  )
  
  validate match(:email, ~r/@/, 
    message: "Please enter a valid email address"
  )
end
```

### Cross-Field Validation

```elixir
actions do
  update :update do
    accept [:start_date, :end_date]
    
    # Validate end_date is after start_date
    validate {MyApp.Validations, :date_range, 
      fields: [:start_date, :end_date]}
  end
end
```

---

## Error Display by Theme

### Default Theme

```elixir
<p :for={{msg, _opts} <- field.errors} class="form-error">
  {msg}
</p>
```

**Renders:**
```html
<p class="form-error">can't be blank</p>
```

### MishkaTheme

```elixir
<.field_hint hint={@field.hint} />
<%= for err <- @field_errors do %>
  <p class="text-xs text-red-600 mt-1">{elem(err, 0)}</p>
<% end %>
```

**Renders:**
```html
<p class="text-xs text-red-600 mt-1">can't be blank</p>
```

### Custom Theme

Implement `render_field/2` in your theme:

```elixir
defmodule MyAppWeb.CustomTheme do
  @behaviour AshFormBuilder.Theme
  
  def render_field(assigns, opts) do
    errors = extract_errors(assigns.form, assigns.field.name)
    
    ~H"""
    <div class="field">
      <label>{@field.label}</label>
      <input class={if errors != [], do: "error"} />
      <%= for {msg, _} <- errors do %>
        <span class="error-msg">{msg}</span>
      <% end %>
    </div>
    """
  end
  
  defp extract_errors(form, field_name) do
    case form[field_name] do
      nil -> []
      field -> field.errors || []
    end
  end
end
```

---

## Nested Form Validation

Nested forms (has_many relationships) validate recursively:

```elixir
# Parent resource
nested :tasks do
  field :title, required: true
  field :due_date, type: :date
end
```

**Error path:** `tasks[0].title: can't be blank`

**How it works:**
```elixir
# FormComponent handles nested paths
def handle_event("validate", %{"form" => params}, socket) do
  # params includes nested structure:
  # %{"tasks" => [%{"title" => "", "due_date" => ...}]}
  
  form = AshPhoenix.Form.validate(socket.assigns.form.source, params)
  # Nested errors automatically extracted and displayed
  {:noreply, assign(socket, form: to_form(form))}
end
```

---

## Combobox Validation

### Search Errors

```elixir
def handle_event("search_team_members", %{"query" => query}, socket) do
  team_members = 
    TeamMember
    |> Ash.Query.filter(ilike(name, ^"%#{query}%"))
    |> Ash.read!(actor: socket.assigns.current_user)
  
  # If search fails, combobox shows error
  {:noreply, push_event(socket, "update_combobox_options", %{
    field: "team_members",
    options: Enum.map(team_members, &{&1.name, &1.id})
  })}
end
```

### Create Errors

```elixir
def handle_event("create_combobox_item", %{...}, socket) do
  case create_new_item(...) do
    {:ok, new_record} ->
      # Success - add to selection
      {:noreply, assign(socket, form: to_form(form))}
    
    {:error, changeset_or_error} ->
      # Show error flash
      Logger.error("Failed to create: #{inspect(changeset_or_error)}")
      {:noreply, put_flash(socket, :error, "Could not create item")}
  end
end
```

---

## Testing Validation

### Test Validation Errors

```elixir
test "validation errors show on required fields", %{conn: conn} do
  {:ok, view, _html} = live_isolated(conn, MyAppWeb.UserLive.Form)

  html =
    view
    |> form("#user-form", %{"email" => ""})
    |> render_submit()

  assert html =~ "can't be blank"
  assert html =~ "required"
end
```

### Test File Upload Validation

```elixir
test "file too large shows error", %{conn: conn} do
  {:ok, view, _html} = live_isolated(conn, MyAppWeb.UserLive.Form)

  big_file = :binary.copy(<<0>>, 6_000_000)  # 6 MB

  upload =
    file_input(view, "#user-form", :avatar, [
      %{name: "huge.jpg", content: big_file, type: "image/jpeg"}
    ])

  html = render_upload(upload, 100)

  assert html =~ "too large" or html =~ "File is too large"
end
```

### Test Custom Validations

```elixir
test "email format validation", %{conn: conn} do
  {:ok, view, _html} = live_isolated(conn, MyAppWeb.UserLive.Form)

  html =
    view
    |> form("#user-form", %{"email" => "not-an-email"})
    |> render_submit()

  assert html =~ "must be a valid email"
end
```

---

## Summary

### What's Automatic ✅

1. **Live Validation** - Runs on every input change
2. **Submit Validation** - Runs all Ash validations + policies
3. **Error Display** - Errors shown below each field
4. **File Upload Validation** - Size, type, count validated
5. **Nested Validation** - Recursive validation for nested forms
6. **Policy Enforcement** - Authorization checked automatically
7. **Error Styling** - Theme applies error styles automatically

### What You Control 🎯

1. **Validations** - Define in your Ash resource
2. **Policies** - Define authorization rules
3. **Error Messages** - Customize in validation definitions
4. **Custom Validations** - Implement custom validation logic
5. **Theme Styling** - Customize error display appearance

### Encapsulation 📦

**AshFormBuilder encapsulates:**
- `AshPhoenix.Form.validate/2` calls
- Error extraction from forms
- Error display rendering
- File upload validation
- Nested form validation
- Combobox error handling

**You just:**
- Define validations in Ash resource
- Use FormComponent in LiveView
- Errors handled automatically!

---

**Version:** 0.2.1  
**See Also:** `FILE_UPLOAD_GUIDE.md`, `STORAGE_CONFIGURATION.md`
