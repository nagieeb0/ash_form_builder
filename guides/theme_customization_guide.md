# Theme Customization Guide

**Version:** 0.2.2  
**Audience:** Developers who want to customize form rendering with their own CSS framework or design system

---

## Table of Contents

1. [Overview](#overview)
2. [How Themes Work](#how-themes-work)
3. [Creating a Custom Theme](#creating-a-custom-theme)
4. [Theme Callbacks Reference](#theme-callbacks-reference)
5. [Common Customization Patterns](#common-customization-patterns)
6. [Using Your Custom Theme](#using-your-custom-theme)
7. [Theme Options](#theme-options)
8. [Troubleshooting](#troubleshooting)

---

## Overview

AshFormBuilder's theme system allows you to completely customize how form fields are rendered without modifying your form logic. You can:

- ✅ Use a different CSS framework (Tailwind, Bootstrap, Bulma, etc.)
- ✅ Customize individual field types (only change checkboxes, keep everything else)
- ✅ Add custom validation error styling
- ✅ Integrate with your design system components
- ✅ Support RTL languages or accessibility requirements

**Built-in Themes:**
- `AshFormBuilder.Themes.Default` - Semantic HTML with minimal CSS classes
- `AshFormBuilder.Theme.MishkaTheme` - MishkaChelekom component integration (requires `mishka_chelekom` dependency)

---

## How Themes Work

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  Your LiveView                                              │
│  <.live_component module={AshFormBuilder.FormComponent} />  │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│  AshFormBuilder.FormComponent                               │
│  - Reads theme from Application.get_env/2                   │
│  - Passes theme to FormRenderer                             │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│  AshFormBuilder.FormRenderer                                │
│  - Iterates form fields                                     │
│  - Calls theme.render_field/2 for each field                │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│  Your Custom Theme Module                                   │
│  - Pattern matches on field.type                            │
│  - Returns Phoenix.LiveView.Rendered (HEEx template)        │
└─────────────────────────────────────────────────────────────┘
```

### Configuration Flow

1. **Configure theme** in `config/config.exs`
2. **FormComponent reads** the theme at runtime
3. **FormRenderer delegates** field rendering to your theme
4. **Your theme renders** HTML with your CSS classes

---

## Creating a Custom Theme

### Step 1: Create the Module

Create a new module in your application (e.g., `lib/my_app_web/form_builder/tailwind_theme.ex`):

```elixir
defmodule MyAppWeb.FormBuilder.TailwindTheme do
  @moduledoc """
  Custom Tailwind CSS theme for AshFormBuilder.
  
  Renders form fields with Tailwind CSS utility classes.
  """
  
  @behaviour AshFormBuilder.Theme
  use Phoenix.Component
```

### Step 2: Implement Required Callbacks

Your theme **MUST** implement `render_field/2`:

```elixir
  @impl AshFormBuilder.Theme
  def render_field(assigns, opts) do
    # Pattern match on field type and render accordingly
    case assigns.field.type do
      :text_input -> render_text_input(assigns)
      :textarea -> render_textarea(assigns)
      :select -> render_select(assigns)
      :checkbox -> render_checkbox(assigns)
      :number -> render_number(assigns)
      :email -> render_email(assigns)
      :password -> render_password(assigns)
      :date -> render_date(assigns)
      :datetime -> render_datetime(assigns)
      :url -> render_url(assigns)
      :tel -> render_tel(assigns)
      :hidden -> render_hidden(assigns)
      :multiselect_combobox -> render_combobox(assigns)
      :file_upload -> render_file_upload(assigns)
      _ -> render_text_input(assigns)
    end
  end
```

### Step 3: Implement Field Rendering Functions

Create private functions for each field type:

```elixir
  defp render_text_input(assigns) do
    ~H"""
    <div class={["mb-4", @field.wrapper_class]}>
      <label
        :if={@field.label}
        for={Phoenix.HTML.Form.input_id(@form, @field.name)}
        class="block text-sm font-medium text-gray-700 mb-1"
      >
        {@field.label}
        <span :if={@field.required} class="text-red-500 ml-1">*</span>
      </label>
      
      <input
        type="text"
        id={Phoenix.HTML.Form.input_id(@form, @field.name)}
        name={Phoenix.HTML.Form.input_name(@form, @field.name)}
        value={Phoenix.HTML.Form.input_value(@form, @field.name)}
        placeholder={@field.placeholder}
        class={"w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 #{@field.class}"}
      />
      
      <.field_hint hint={@field.hint} />
      <.field_errors form={@form} field={@field.name} />
    </div>
    """
  end
  
  defp render_checkbox(assigns) do
    ~H"""
    <div class={["mb-4", @field.wrapper_class]}>
      <div class="flex items-center">
        <input
          type="hidden"
          name={Phoenix.HTML.Form.input_name(@form, @field.name)}
          value="false"
        />
        <input
          type="checkbox"
          id={Phoenix.HTML.Form.input_id(@form, @field.name)}
          name={Phoenix.HTML.Form.input_name(@form, @field.name)}
          value="true"
          checked={Phoenix.HTML.Form.input_value(@form, @field.name) in [true, "true"]}
          class="h-4 w-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500"
        />
        <label
          :if={@field.label}
          for={Phoenix.HTML.Form.input_id(@form, @field.name)}
          class="ml-2 block text-sm text-gray-900"
        >
          {@field.label}
          <span :if={@field.required} class="text-red-500 ml-1">*</span>
        </label>
      </div>
      
      <.field_errors form={@form} field={@field.name} />
    </div>
    """
  end
  
  # ... implement other field types
```

### Step 4: Add Helper Components

Create shared sub-components for hints and errors:

```elixir
  attr(:hint, :string, default: nil)
  
  defp field_hint(%{hint: nil} = _assigns), do: ~H""
  
  defp field_hint(assigns) do
    ~H"""
    <p class="text-xs text-gray-500 mt-1">{@hint}</p>
    """
  end
  
  attr(:form, :any, required: true)
  attr(:field, :any, required: true)
  
  defp field_errors(assigns) do
    ~H"""
    <p
      :for={{msg, _opts} <- Keyword.get_values((@form[@field.name] || %{errors: []}).errors, :message)}
      class="text-xs text-red-600 mt-1"
    >
      {msg}
    </p>
    """
  end
```

### Step 5: Implement Optional Callbacks (Optional)

```elixir
  @impl AshFormBuilder.Theme
  def render_nested(assigns) do
    # Return nil to use default nested form rendering
    # Or implement custom nested form rendering
    nil
  end
  
  @impl AshFormBuilder.Theme
  def render_component(:combobox, assigns) do
    # Custom component rendering for specific types
    # Optional - for advanced customization
  end
  
  def render_component(_, _), do: nil
```

### Step 6: End the Module

```elixir
end
```

---

## Theme Callbacks Reference

### Required Callbacks

#### `c:AshFormBuilder.Theme.render_field/2`

```elixir
@callback render_field(assigns :: map(), opts :: keyword()) :: Phoenix.LiveView.Rendered.t()
```

**Assigns Available:**
| Key | Type | Description |
|-----|------|-------------|
| `:form` | `Phoenix.HTML.Form` | The form struct |
| `:field` | `AshFormBuilder.Field` | Field metadata (name, type, label, etc.) |
| `:target` | `pid() | String.t()` | LiveComponent target (`@myself`) |
| `:uploads` | `map()` | Upload configurations for file fields |
| `:theme_opts` | `keyword()` | Theme-specific options |

**Field Struct (`AshFormBuilder.Field`):**
| Key | Type | Description |
|-----|------|-------------|
| `:name` | `atom()` | Field name (e.g., `:email`) |
| `:label` | `String.t()` | Field label |
| `:type` | `atom()` | Field type (e.g., `:text_input`, `:checkbox`) |
| `:required` | `boolean()` | Whether field is required |
| `:placeholder` | `String.t()` | Placeholder text |
| `:hint` | `String.t()` | Helper text |
| `:options` | `list()` | Options for `:select` fields |
| `:class` | `String.t()` | Additional CSS classes |
| `:wrapper_class` | `String.t()` | Wrapper div CSS classes |
| `:relationship` | `atom()` | Relationship name (for relationship fields) |
| `:relationship_type` | `atom()` | `:many_to_many`, `:has_many`, etc. |
| `:destination_resource` | `module()` | Related resource module |
| `:opts` | `keyword()` | Custom options (e.g., `search_event` for combobox) |

---

### Optional Callbacks

#### `c:AshFormBuilder.Theme.render_nested/1`

```elixir
@callback render_nested(assigns :: map()) :: Phoenix.LiveView.Rendered.t() | nil
```

**Assigns Available:**
| Key | Type | Description |
|-----|------|-------------|
| `:form` | `Phoenix.HTML.Form` | The parent form |
| `:nested` | `AshFormBuilder.NestedForm` | Nested form configuration |
| `:target` | `pid() | String.t()` | LiveComponent target |
| `:theme` | `module()` | The theme module |

**Return:** `nil` to use default rendering, or a rendered template.

#### `c:AshFormBuilder.Theme.render_component/2`

```elixir
@callback render_component(atom(), assigns :: map()) :: Phoenix.LiveView.Rendered.t() | nil
```

For advanced customization of specific component types.

---

## Common Customization Patterns

### Pattern 1: Extend Default Theme (Minimal Changes)

Only override specific field types, delegate the rest to Default:

```elixir
defmodule MyAppWeb.FormBuilder.MinimalTheme do
  @behaviour AshFormBuilder.Theme
  use Phoenix.Component
  
  # Delegate render_field/2 to Default theme
  defdelegate render_field(assigns, opts), to: AshFormBuilder.Themes.Default
  
  # Optional: override render_nested/1
  @impl AshFormBuilder.Theme
  def render_nested(assigns), do: nil
end
```

### Pattern 2: Wrapper Component Pattern

Wrap all fields in a consistent structure:

```elixir
defp render_text_input(assigns) do
  ~H"""
  <div class={["form-field", @field.wrapper_class]}>
    <div class="form-field-label">
      <label for={Phoenix.HTML.Form.input_id(@form, @field.name)}>
        {@field.label}
      </label>
      <span :if={@field.required} class="required-indicator">*</span>
    </div>
    
    <div class="form-field-input">
      <input ... />
    </div>
    
    <div class="form-field-hint">
      <.field_hint hint={@field.hint} />
      <.field_errors form={@form} field={@field.name} />
    </div>
  </div>
  """
end
```

### Pattern 3: CSS Framework Integration (Bootstrap Example)

```elixir
defmodule MyAppWeb.FormBuilder.BootstrapTheme do
  @behaviour AshFormBuilder.Theme
  use Phoenix.Component
  
  @impl AshFormBuilder.Theme
  def render_field(assigns, opts) do
    case assigns.field.type do
      :text_input -> render_text_input(assigns)
      :checkbox -> render_checkbox(assigns)
      # ... etc
    end
  end
  
  defp render_text_input(assigns) do
    ~H"""
    <div class="mb-3">
      <label for={Phoenix.HTML.Form.input_id(@form, @field.name)} class="form-label">
        {@field.label}
        <span :if={@field.required} class="text-danger">*</span>
      </label>
      
      <input
        type="text"
        id={Phoenix.HTML.Form.input_id(@form, @field.name)}
        name={Phoenix.HTML.Form.input_name(@form, @field.name)}
        value={Phoenix.HTML.Form.input_value(@form, @field.name)}
        class={"form-control #{@field.class}"}
        placeholder={@field.placeholder}
      />
      
      <div :if={@field.hint} class="form-text">{@field.hint}</div>
      
      <.field_errors form={@form} field={@field.name} />
    </div>
    """
  end
  
  @impl AshFormBuilder.Theme
  def render_nested(assigns), do: nil
  
  defp field_errors(assigns) do
    ~H"""
    <div
      :for={{msg, _opts} <- Keyword.get_values((@form[@field.name] || %{errors: []}).errors, :message)}
      class="invalid-feedback d-block"
    >
      {msg}
    </div>
    """
  end
end
```

### Pattern 4: Accessibility-Focused Theme

Add ARIA attributes and accessibility features:

```elixir
defp render_text_input(assigns) do
  error_id = "error-#{Phoenix.HTML.Form.input_id(@form, @field.name)}"
  hint_id = "hint-#{Phoenix.HTML.Form.input_id(@form, @field.name)}"
  has_errors = length((@form[@field.name] || %{errors: []}).errors) > 0
  
  ~H"""
  <div class={["form-group", @field.wrapper_class]}>
    <label
      :if={@field.label}
      for={Phoenix.HTML.Form.input_id(@form, @field.name)}
      class="form-label"
    >
      {@field.label}
      <span :if={@field.required} aria-hidden="true" class="required">*</span>
    </label>
    
    <input
      type="text"
      id={Phoenix.HTML.Form.input_id(@form, @field.name)}
      name={Phoenix.HTML.Form.input_name(@form, @field.name)}
      value={Phoenix.HTML.Form.input_value(@form, @field.name)}
      class={"form-input #{@field.class}"}
      class={if has_errors, do: "border-red-500", else: "border-gray-300"}
      placeholder={@field.placeholder}
      aria-describedby={if @field.hint, do: hint_id}
      aria-invalid={if has_errors, do: "true", else: "false"}
      aria-errormessage={if has_errors, do: error_id}
    />
    
    <p
      :if={@field.hint}
      id={hint_id}
      class="form-hint text-sm text-gray-500"
    >
      {@field.hint}
    </p>
    
    <p
      :for={{msg, _opts} <- Keyword.get_values((@form[@field.name] || %{errors: []}).errors, :message)}
      id={error_id}
      class="form-error text-sm text-red-600"
      role="alert"
    >
      {msg}
    </p>
  </div>
  """
end
```

### Pattern 5: RTL Language Support

```elixir
defp render_text_input(assigns) do
  dir = Keyword.get(@theme_opts, :dir, "ltr")
  
  ~H"""
  <div class={["form-group", @field.wrapper_class]} dir={dir}>
    <label
      :if={@field.label}
      for={Phoenix.HTML.Form.input_id(@form, @field.name)}
      class="form-label"
    >
      {@field.label}
    </label>
    
    <input
      type="text"
      id={Phoenix.HTML.Form.input_id(@form, @field.name)}
      name={Phoenix.HTML.Form.input_name(@form, @field.name)}
      value={Phoenix.HTML.Form.input_value(@form, @field.name)}
      class={"form-input #{@field.class}"}
      dir={dir}
    />
  </div>
  """
end

# Configure in config.exs:
# config :ash_form_builder, theme_opts: [dir: "rtl"]
```

---

## Using Your Custom Theme

### Step 1: Configure Globally

```elixir
# config/config.exs
config :ash_form_builder,
  theme: MyAppWeb.FormBuilder.TailwindTheme,
  theme_opts: [
    wrapper_class: "space-y-6",
    field_wrapper_class: "mb-4",
    label_class: "block text-sm font-medium mb-1",
    input_class: "w-full px-3 py-2 border rounded-md"
  ]
```

### Step 2: Use in LiveView

```elixir
defmodule MyAppWeb.ClinicLive.Form do
  use MyAppWeb, :live_view
  
  @impl true
  def mount(_params, _session, socket) do
    form = MyApp.Billing.Clinic.Form.for_create(actor: socket.assigns.current_user)
    {:ok, assign(socket, form: form)}
  end
  
  @impl true
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
end
```

### Step 3: Runtime Theme Switching (Advanced)

Pass theme explicitly to FormRenderer:

```elixir
# In your LiveView
def render(assigns) do
  ~H"""
  <.live_component
    module={AshFormBuilder.FormComponent}
    id="clinic-form"
    resource={MyApp.Billing.Clinic}
    form={@form}
    theme={MyAppWeb.FormBuilder.TailwindTheme}
  />
  """
end
```

---

## Theme Options

Theme options are passed via `config.exs` and accessible in `opts` parameter:

```elixir
# config/config.exs
config :ash_form_builder,
  theme: MyAppWeb.FormBuilder.TailwindTheme,
  theme_opts: [
    # Global wrapper class
    wrapper_class: "space-y-6",
    
    # Field wrapper class
    field_wrapper_class: "mb-4",
    
    # Label class
    label_class: "block text-sm font-medium mb-1",
    
    # Input class (applied to all inputs)
    input_class: "w-full px-3 py-2 border rounded-md",
    
    # Error class
    error_class: "text-sm text-red-600 mt-1",
    
    # Hint class
    hint_class: "text-xs text-gray-500 mt-1",
    
    # Custom options for your theme
    custom_option: "value"
  ]
```

Access in your theme:

```elixir
defp render_text_input(assigns) do
  input_class = Keyword.get(@theme_opts, :input_class, "form-input")
  
  ~H"""
  <input class={input_class} />
  """
end
```

---

## Troubleshooting

### Problem: Theme module not found

**Error:** `module AshFormBuilder.Theme.MishkaTheme is not loaded`

**Solution:**
1. Ensure the theme module is compiled
2. Add `Code.ensure_loaded?(MyTheme)` in test setup if testing
3. Check module name matches config

### Problem: Field not rendering

**Error:** Field appears blank or missing

**Solution:**
1. Check `render_field/2` pattern matches the field type
2. Ensure you're returning a HEEx template (`~H"..."`)
3. Verify `Phoenix.LiveView.Rendered` struct is returned

### Problem: CSS classes not applying

**Error:** Styles not showing up

**Solution:**
1. Check class names match your CSS framework
2. Verify `@field.class` and `@field.wrapper_class` are included
3. Check for typos in class names

### Problem: Errors not displaying

**Error:** Validation errors don't show

**Solution:**
```elixir
# Ensure you're extracting errors correctly:
defp field_errors(assigns) do
  ~H"""
  <p
    :for={{msg, _opts} <- Keyword.get_values((@form[@field.name] || %{errors: []}).errors, :message)}
    class="text-red-600"
  >
    {msg}
  </p>
  """
end
```

### Problem: Nested forms not rendering

**Error:** Nested relationship forms don't appear

**Solution:**
1. Implement `render_nested/1` callback OR return `nil` for default
2. Check `AshFormBuilder.FormRenderer.nested_form/1` is being called
3. Verify nested form configuration in resource DSL

---

## Complete Example: Tailwind Theme

See a complete working example at:
`lib/ash_form_builder/themes/default.ex` (Default theme)
`lib/ash_form_builder/theme/mishka_theme.ex` (MishkaChelekom theme)

---

## Next Steps

1. **Start with Default** - Copy `AshFormBuilder.Themes.Default` and modify
2. **Test incrementally** - Change one field type at a time
3. **Use theme_opts** - Make your theme configurable
4. **Document your theme** - Add `@moduledoc` with usage examples
5. **Share with community** - Publish your theme as a separate package

---

## See Also

- [AshFormBuilder README](../README.md)
- [MishkaChelekom Documentation](https://hexdocs.pm/mishka_chelekom)
- [Phoenix LiveView Documentation](https://hexdocs.pm/phoenix_live_view)
