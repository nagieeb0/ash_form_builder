# AshFormBuilder v0.2.0 Implementation Guide

## Executive Summary

This guide outlines the complete implementation plan for upgrading ash_form_builder from v0.1.x to v0.2.0 "Production-Ready".

**Status:**
- ✅ Task 1: Metadata & Hex.pm Presence - **COMPLETE**
- 🔄 Task 2-6: Implementation in progress

---

## Task 2: Architecture Refactor for "Zero-Config" Inference

### 2.1 Enhance AshFormBuilder.Infer Engine

**File:** `lib/ash_form_builder/infer.ex`

#### Required Changes:

```elixir
defmodule AshFormBuilder.Infer do
  @moduledoc """
  Zero-Config Auto-Inference Engine for AshFormBuilder v0.2.0.
  
  ## Capabilities
  
  * Detects all accept attributes, arguments, and relationships automatically
  * Maps Ash types to UI components with sensible defaults
  * Supports field ignoring and ordering without full field blocks
  * Respects manage_relationship configurations
  """
  
  # Enhanced type mapping with ALL Ash 3.0 types
  @type_map %{
    # String types
    Ash.Type.String => :text_input,
    :string => :text_input,
    Ash.Type.CiString => :text_input,
    :ci_string => :text_input,
    
    # Boolean
    Ash.Type.Boolean => :checkbox,
    :boolean => :checkbox,
    
    # Numeric
    Ash.Type.Integer => :number,
    :integer => :number,
    Ash.Type.Float => :number,
    :float => :number,
    Ash.Type.Decimal => :number,
    :decimal => :number,
    
    # Date/Time
    Ash.Type.Date => :date,
    :date => :date,
    Ash.Type.DateTime => :datetime,
    :datetime => :datetime,
    Ash.Type.UtcDatetime => :datetime,
    :utc_datetime => :datetime,
    Ash.Type.UtcDatetimeUsec => :datetime,
    :utc_datetime_usec => :datetime,
    Ash.Type.NaiveDatetime => :datetime,
    :naive_datetime => :datetime,
    Ash.Type.NaiveDatetimeUsec => :datetime,
    :naive_datetime_usec => :datetime,
    
    # Special types
    Ash.Type.URL => :url,
    :url => :url,
    Ash.Type.Email => :email,
    :email => :email,
    Ash.Type.Phone => :tel,
    :phone => :tel,
    
    # Atom/Enum
    Ash.Type.Atom => :text_input,  # Will be overridden by constraints
    :atom => :text_input,
    Ash.Type.Enum => :select,
    
    # Binary/Map (fallback to text)
    Ash.Type.Binary => :textarea,
    :binary => :textarea,
    Ash.Type.Map => :textarea,
    :map => :textarea,
    
    # UUID (usually hidden or text)
    Ash.Type.UUID => :text_input,
    :uuid => :text_input,
    
    # Money
    Ash.Type.Money => :number,
    :money => :number
  }
  
  @doc """
  Infers fields with zero-config operation.
  
  ## Options
  
  * `:ignore_fields` - List of field names to skip (default: [:id, :inserted_at, :updated_at])
  * `:include_timestamps` - Whether to include timestamp fields (default: false)
  * `:many_to_many_as` - UI type for many_to_many (default: :multiselect_combobox)
  * `:has_many_as` - UI type for has_many (default: :nested_form)
  * `:belongs_to_as` - UI type for belongs_to (default: :select)
  
  ## Examples
  
      # Zero-config - infer everything
      infer_fields(MyApp.Task, :create)
      
      # Custom ignore list
      infer_fields(MyApp.Task, :create, ignore_fields: [:id, :tenant_id])
      
      # Include timestamps
      infer_fields(MyApp.Task, :create, include_timestamps: true)
      
      # Customize relationship UI
      infer_fields(MyApp.Task, :create, many_to_many_as: :select)
  """
  @spec infer_fields(module(), atom(), keyword()) :: [Field.t()]
  def infer_fields(resource, action_name, opts \\ []) do
    action = Ash.Resource.Info.action(resource, action_name)
    
    if is_nil(action) do
      []
    else
      opts = Keyword.validate!(opts, [
        ignore_fields: [:id, :inserted_at, :updated_at],
        include_timestamps: false,
        many_to_many_as: :multiselect_combobox,
        has_many_as: :nested_form,
        belongs_to_as: :select
      ])
      
      # Process accept list
      accept_fields = process_accept_list(resource, action.accept || [], opts)
      
      # Process arguments  
      arg_fields = process_arguments(action.arguments || [])
      
      accept_fields ++ arg_fields
    end
  end
  
  defp process_accept_list(resource, accept, opts) do
    accept
    |> Enum.reject(&should_ignore?(&1, opts))
    |> Enum.map(&infer_field(resource, &1, opts))
    |> Enum.reject(&is_nil/1)
  end
  
  defp should_ignore?(field_name, opts) do
    field_name in opts[:ignore_fields] or
    (not opts[:include_timestamps] and field_name in [:inserted_at, :updated_at])
  end
  
  defp infer_field(resource, field_name, opts) do
    case detect_field_type(resource, field_name) do
      :attribute -> infer_from_attribute(resource, field_name, opts)
      {:relationship, rel} -> infer_from_relationship(rel, opts)
      :ignore -> nil
    end
  end
  
  # Smart constraint detection
  defp infer_type(:atom, constraints) do
    case constraints[:one_of] do
      nil -> :text_input
      _ -> :select
    end
  end
  
  defp infer_type(type, constraints) when is_atom(type) do
    cond do
      Map.has_key?(@type_map, type) -> Map.get(@type_map, type)
      function_exported?(type, :values, 0) -> :select  # Enum module
      true -> :text_input
    end
  end
end
```

### 2.2 Add DSL Options for Field Control

**File:** `lib/ash_form_builder/dsl.ex`

```elixir
@form %Spark.Dsl.Section{
  name: :form,
  describe: "Declares the auto-generated LiveView form for this Ash resource.",
  entities: [@field, @nested_form],
  schema: [
    action: [
      type: :atom,
      required: true,
      doc: "The Ash action this form targets."
    ],
    submit_label: [
      type: :string,
      default: "Submit",
      doc: "Label for the submit button."
    ],
    ignore_fields: [
      type: {:list, :atom},
      default: [:id, :inserted_at, :updated_at],
      doc: "Fields to exclude from auto-inference."
    ],
    field_order: [
      type: {:list, :atom},
      doc: "Custom ordering for fields. Fields not listed appear after."
    ],
    include_timestamps: [
      type: :boolean,
      default: false,
      doc: "Whether to include :inserted_at and :updated_at fields."
    ],
    module: [
      type: :atom,
      doc: "Override the auto-generated helper module name."
    ],
    form_id: [
      type: :string,
      doc: "HTML `id` attribute for the `<form>` element."
    ],
    wrapper_class: [
      type: :string,
      default: "space-y-4",
      doc: "CSS class applied to the fields wrapper `<div>`."
    ]
  ]
}

@field %Spark.Dsl.Entity{
  name: :field,
  target: AshFormBuilder.Field,
  args: [:name],
  schema: [
    name: [
      type: :atom,
      required: true,
      doc: "The attribute or relationship name."
    ],
    ignore: [
      type: :boolean,
      default: false,
      doc: "Set to true to exclude this field from rendering."
    ],
    order: [
      type: :integer,
      doc: "Custom sort order. Lower numbers appear first."
    ],
    # ... existing options
  ]
}
```

---

## Task 3: Deep Relationship & Nested Form Mastery

### 3.1 Robust manage_relationship Handling

**File:** `lib/ash_form_builder/infer.ex`

```elixir
defp infer_from_relationship(rel, opts) do
  manage_type = get_manage_type(rel)
  
  case {rel.type, manage_type} do
    # many_to_many with append_and_remove → multiselect_combobox
    {:many_to_many, :append_and_remove} ->
      build_combobox_field(rel, opts)
    
    # many_to_many with :create → creatable combobox  
    {:many_to_many, :create} ->
      build_creatable_combobox_field(rel, opts)
    
    # has_many with :create → nested form
    {:has_many, type} when type in [:create, :create_and_destroy] ->
      build_nested_form_field(rel, opts)
    
    # belongs_to → select or combobox
    {:belongs_to, _} ->
      build_belongs_to_field(rel, opts)
    
    _ -> nil
  end
end

defp get_manage_type(rel) do
  # Extract manage_relationship type from action configuration
  # This requires inspecting the action's relationship management
  :append_and_remove  # Default
end
```

### 3.2 Deeply Nested Structures (3+ Levels)

**File:** `lib/ash_form_builder/form_component.ex`

```elixir
@impl Phoenix.LiveComponent
def handle_event("add_form", %{"path" => path}, socket) do
  # Support deeply nested paths like "subtasks[0].items[1].subitems"
  form = AshPhoenix.Form.add_form(socket.assigns.form.source, parse_path(path))
  {:noreply, assign(socket, form: to_form(form))}
end

defp parse_path(path_string) do
  # Convert "subtasks[0].items[1]" to proper path structure
  path_string
  |> String.split(".")
  |> Enum.map(&parse_segment/1)
end

defp parse_segment(segment) do
  case Regex.run(~r/^(\w+)\[(\d+)\]$/, segment) do
    [_, field, index] -> {String.to_atom(field), String.to_integer(index)}
    _ -> String.to_atom(segment)
  end
end
```

### 3.3 Performance Optimization with LiveComponent Boundaries

**File:** `lib/ash_form_builder/nested_form_component.ex` (New File)

```elixir
defmodule AshFormBuilder.NestedFormComponent do
  @moduledoc """
  Isolated LiveComponent for nested form entries.
  
  Prevents unnecessary re-renders of sibling nested forms.
  """
  
  use Phoenix.LiveComponent
  
  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changed?, Map.get(assigns, :changed?, false))}
  end
  
  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div class="nested-form-entry" id={@id}>
      <%= for field <- @fields do %>
        <%= @theme.render_field(%{form: @form, field: field}, []) %>
      <% end %>
      
      <button
        type="button"
        phx-click="remove_form"
        phx-target={@myself}
      >
        Remove
      </button>
    </div>
    """
  end
  
  @impl Phoenix.LiveComponent
  def handle_event("remove_form", _params, socket) do
    # Remove this nested form entry
    form = AshPhoenix.Form.remove_form(socket.assigns.form.source, socket.assigns.path)
    send(self(), {:nested_form_removed, socket.assigns.id})
    {:noreply, assign(socket, form: to_form(form))}
  end
end
```

---

## Task 4: Pluggable Theme System Upgrade

### 4.1 Enhanced Theme Behaviour

**File:** `lib/ash_form_builder/theme.ex`

```elixir
defmodule AshFormBuilder.Theme do
  @moduledoc """
  Behaviour for comprehensive theme customization.
  
  Supports:
  - Custom field rendering per type
  - Nested form customization
  - Component injection for specific field types
  - Full control over HTML structure and CSS classes
  """
  
  @doc """
  Renders a complete field with all UI elements.
  
  ## Assigns
  
  * `:form` - Phoenix.HTML.Form
  * `:field` - AshFormBuilder.Field
  * `:theme_opts` - Theme-specific options passed from renderer
  
  ## Opts
  
  Additional options from the field DSL or renderer.
  """
  @callback render_field(assigns :: map(), opts :: keyword()) :: 
    Phoenix.LiveView.Rendered.t()
  
  @doc """
  Renders a nested form block.
  
  Return `nil` to use default nested form rendering.
  """
  @callback render_nested(assigns :: map()) :: 
    Phoenix.LiveView.Rendered.t() | nil
  
  @optional_callbacks render_nested: 1
  
  @doc """
  Renders a specific component type.
  
  Allows themes to inject custom components for specific field types.
  """
  @callback render_component(atom(), assigns :: map()) :: 
    Phoenix.LiveView.Rendered.t() | nil
  
  @optional_callbacks render_component: 2
end
```

### 4.2 Theme Configuration

**File:** `config/config.exs`

```elixir
config :ash_form_builder,
  theme: AshFormBuilder.Themes.Default,
  theme_opts: [
    # Global theme options
    wrapper_class: "space-y-6",
    field_wrapper_class: "mb-4",
    label_class: "block text-sm font-medium mb-1",
    input_class: "w-full px-3 py-2 border rounded-md",
    error_class: "text-sm text-red-600 mt-1",
    hint_class: "text-sm text-gray-500 mt-1"
  ]
```

---

## Task 5: Advanced Searchable/Creatable Combobox

### 5.1 Server-Side Search Integration

**File:** `lib/ash_form_builder/form_component.ex`

```elixir
@impl Phoenix.LiveComponent
def handle_event("search_" <> field_name, params, socket) do
  query = params["query"] || ""
  field = String.to_atom(field_name)
  
  # Get field configuration
  field_config = get_field_config(socket.assigns.entities, field)
  
  # Build search query using Ash.Query
  results = search_relationship(
    field_config.destination_resource,
    query,
    field_config.opts,
    socket.assigns[:actor]
  )
  
  # Push options update event
  {:noreply, push_event(socket, "update_combobox_options", %{
    field: field_name,
    options: Enum.map(results, &{get_label(&1, field_config), get_value(&1, field_config)}),
    creatable: field_config.opts[:creatable] || false
  })}
end

defp search_relationship(resource, query, opts, actor) do
  label_key = opts[:label_key] || :name
  
  resource
  |> Ash.Query.filter(contains(^label_key, ^query))
  |> Ash.Query.limit(50)
  |> Ash.read!(actor: actor)
end
```

### 5.2 Creatable Implementation

```elixir
@impl Phoenix.LiveComponent
def handle_event("create_combobox_item", %{
  "field" => field_name,
  "value" => value,
  "resource" => resource_mod
}, socket) do
  resource = String.to_atom(resource_mod)
  field = String.to_atom(field_name)
  
  # Get primary attribute
  primary_attr = get_primary_attribute(resource)
  
  # Create new record
  case Ash.create(resource, %{primary_attr => value}, actor: socket.assigns[:actor]) do
    {:ok, new_record} ->
      # Add to current selection
      form = socket.assigns.form.source
      current = AshPhoenix.Form.value(form, field) || []
      updated = Enum.uniq(current ++ [Map.get(new_record, :id)])
      
      form = AshPhoenix.Form.validate(form, %{field => updated})
      {:noreply, assign(socket, form: to_form(form))}
    
    {:error, changeset} ->
      # Show error to user
      {:noreply, put_flash(socket, :error, "Could not create: #{inspect(changeset.errors)}")}
  end
end
```

---

## Task 6: Comprehensive Testing

### 6.1 Test Helpers

**File:** `test/support/ash_form_builder_helpers.ex` (New File)

```elixir
defmodule AshFormBuilder.TestHelpers do
  @moduledoc """
  Test helpers for AshFormBuilder components.
  """
  
  import Phoenix.LiveViewTest
  
  @doc """
  Renders a form component and extracts field HTML.
  """
  def render_form_fields(conn, live_view_module, opts \\ []) do
    {:ok, view, _html} = live_isolated(conn, live_view_module, opts)
    render(view)
  end
  
  @doc """
  Asserts that a form contains expected field types.
  """
  def assert_form_fields(html, expected_fields) do
    for {field_name, field_type} <- expected_fields do
      assert has_field?(html, field_name, field_type),
        "Expected field #{field_name} of type #{field_type}"
    end
  end
  
  defp has_field?(html, field_name, :text_input) do
    html =~ "name=\"#{field_name}\"" and html =~ "type=\"text\""
  end
  
  defp has_field?(html, field_name, :textarea) do
    html =~ "name=\"#{field_name}\"" and html =~ "<textarea"
  end
  
  defp has_field?(html, field_name, :checkbox) do
    html =~ "name=\"#{field_name}\"" and html =~ "type=\"checkbox\""
  end
  
  defp has_field?(html, field_name, :multiselect_combobox) do
    html =~ "name=\"#{field_name}\"" and html =~ "combobox"
  end
end
```

### 6.2 Integration Tests

**File:** `test/ash_form_builder/infer_integration_test.exs` (New File)

```elixir
defmodule AshFormBuilder.InferIntegrationTest do
  use ExUnit.Case, async: true
  
  alias AshFormBuilder.Infer
  alias AshFormBuilder.Test.Resources.{Task, Category, Tag}
  
  describe "zero-config inference" do
    test "infers all accept attributes correctly" do
      fields = Infer.infer_fields(Task, :create)
      
      assert length(fields) > 0
      assert Enum.any?(fields, &(&1.name == :title))
      assert Enum.any?(fields, &(&1.type == :text_input))
    end
    
    test "respects ignore_fields option" do
      fields = Infer.infer_fields(Task, :create, ignore_fields: [:title])
      
      refute Enum.any?(fields, &(&1.name == :title))
    end
    
    test "includes timestamps when requested" do
      fields_with = Infer.infer_fields(Task, :create, include_timestamps: true)
      fields_without = Infer.infer_fields(Task, :create, include_timestamps: false)
      
      assert length(fields_with) > length(fields_without)
    end
  end
  
  describe "relationship inference" do
    test "many_to_many → multiselect_combobox" do
      fields = Infer.infer_fields(Task, :create)
      tags_field = Enum.find(fields, &(&1.name == :tags))
      
      assert tags_field.type == :multiselect_combobox
      assert tags_field.destination_resource == Tag
    end
    
    test "creatable combobox configuration" do
      fields = Infer.infer_fields(Task, :create)
      tags_field = Enum.find(fields, &(&1.name == :tags))
      
      assert tags_field.opts[:creatable] == true
      assert tags_field.opts[:create_action] == :create
    end
  end
end
```

---

## Testing & Validation

Run the full test suite:

```bash
mix test
mix test --coverage
mix format
mix credo --strict
```

---

## Release Checklist

- [ ] All tests passing
- [ ] Documentation updated
- [ ] CHANGELOG updated with breaking changes
- [ ] Version bumped to 0.2.0
- [ ] Git tag created
- [ ] Published to hex.pm
- [ ] GitHub release created

---

**Last Updated:** 2024-12-19  
**Version:** 0.2.0  
**Status:** Implementation Guide
