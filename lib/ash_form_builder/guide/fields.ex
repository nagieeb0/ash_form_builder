defmodule AshFormBuilder.Guide.Fields do
  @moduledoc """
  # Fields Guide

  Complete reference for all field types and their customization options.

  ## Contents

  1. [Auto-Inference](#module-auto-inference)
  2. [Standard Field Types](#module-standard-field-types)
  3. [Combobox Fields](#module-combobox-fields)
  4. [Nested Forms](#module-nested-forms)
  5. [Field Options Reference](#module-field-options-reference)
  6. [Examples](#module-examples)

  ---

  ## Auto-Inference

  Fields are automatically inferred from your Ash action's `accept` list.

  ### Inference Mapping

  | Ash Type | Constraint | Inferred UI Type | Example |
  |----------|------------|------------------|---------|
  | `:string` | - | `:text_input` | Text fields |
  | `:ci_string` | - | `:text_input` | Case-insensitive text |
  | `:text` | - | `:textarea` | Multi-line text |
  | `:boolean` | - | `:checkbox` | Toggle switches |
  | `:integer` | - | `:number` | Whole numbers |
  | `:float` | - | `:number` | Decimal numbers |
  | `:decimal` | - | `:number` | Precise decimals |
  | `:date` | - | `:date` | Date picker |
  | `:datetime` | - | `:datetime` | DateTime picker |
  | `:utc_datetime` | - | `:datetime` | UTC DateTime |
  | `:atom` | `one_of:` | `:select` | Dropdown |
  | `:enum` module | - | `:select` | Enum dropdown |
  | `many_to_many` | - | `:multiselect_combobox` | Searchable multi-select |

  ### Example: Auto-Inferred Form

  ```elixir
  defmodule MyApp.Todos.Task do
    attributes do
      attribute :title, :string, allow_nil?: false
      attribute :description, :text
      attribute :priority, :atom, constraints: [one_of: [:low, :medium, :high]]
      attribute :due_date, :date
      attribute :completed, :boolean, default: false
    end

    actions do
      create :create do
        accept [:title, :description, :priority, :due_date, :completed]
      end
    end

    form do
      action :create
      # All fields auto-inferred!
    end
  end
  ```

  ---

  ## Standard Field Types

  ### Text Input

  Default for `:string` and `:ci_string` types.

  ```elixir
  field :title do
    label "Task Title"
    type :text_input
    placeholder "Enter title"
    required true
    hint "Keep it concise"
    class "input-lg"
    wrapper_class "mb-4"
  end
  ```

  **Renders:**
  ```html
  <div class="mb-4">
    <label>Task Title <span class="text-error">*</span></label>
    <input type="text" placeholder="Enter title" />
    <p class="text-xs">Keep it concise</p>
  </div>
  ```

  ### Textarea

  For `:text` or multi-line input.

  ```elixir
  field :description do
    label "Description"
    type :textarea
    placeholder "Add details..."
    rows 4
    hint "Optional but helpful"
  end
  ```

  **Renders:**
  ```html
  <div>
    <label>Description</label>
    <textarea rows="4" placeholder="Add details..."></textarea>
  </div>
  ```

  ### Select (Dropdown)

  For `:atom` with `one_of:` constraint or `:enum` types.

  ```elixir
  field :priority do
    label "Priority"
    type :select
    options: [
      {"Low", :low},
      {"Medium", :medium},
      {"High", :high}
    ]
    default :medium
    hint "How important is this?"
  end
  ```

  **Renders:**
  ```html
  <div>
    <label>Priority</label>
    <select>
      <option value="low">Low</option>
      <option value="medium" selected>Medium</option>
      <option value="high">High</option>
    </select>
  </div>
  ```

  ### Checkbox

  For `:boolean` types.

  ```elixir
  field :completed do
    label "Completed"
    type :checkbox
    hint "Mark as done"
  end
  ```

  **Renders:**
  ```html
  <div>
    <label>
      <input type="checkbox" />
      Completed
    </label>
  </div>
  ```

  ### Number

  For `:integer`, `:float`, `:decimal`.

  ```elixir
  field :estimated_hours do
    label "Estimated Hours"
    type :number
    placeholder "0"
    min 0
    step "0.5"
  end
  ```

  ### Date

  For `:date` types.

  ```elixir
  field :due_date do
    label "Due Date"
    type :date
    min Date.to_string(Date.utc_today())
    hint "When should this be done?"
  end
  ```

  ### DateTime

  For `:datetime`, `:utc_datetime`, `:naive_datetime`.

  ```elixir
  field :scheduled_at do
    label "Scheduled At"
    type :datetime
    hint "When to start working on this"
  end
  ```

  ### Email

  Email input with validation.

  ```elixir
  field :email do
    label "Email Address"
    type :email
    placeholder "you@example.com"
  end
  ```

  ### Password

  Password input (masked).

  ```elixir
  field :password do
    label "Password"
    type :password
    placeholder "••••••••"
    required true
  end
  ```

  ### URL

  URL input.

  ```elixir
  field :website do
    label "Website"
    type :url
    placeholder "https://example.com"
  end
  ```

  ### Tel

  Telephone input.

  ```elixir
  field :phone do
    label "Phone Number"
    type :tel
    placeholder "+1 (555) 123-4567"
  end
  ```

  ### Hidden

  Hidden field for IDs and metadata.

  ```elixir
  field :id do
    type :hidden
  end
  ```

  ---

  ## Combobox Fields

  ### Multiselect Combobox

  For `many_to_many` relationships.

  ```elixir
  field :tags do
    type :multiselect_combobox
    label "Tags"
    placeholder "Search tags..."
    required false

    opts [
      search_event: "search_tags",
      debounce: 300,
      label_key: :name,
      value_key: :id,
      hint: "Add tags to categorize"
    ]
  end
  ```

  **LiveView Handler:**
  ```elixir
  def handle_event("search_tags", %{"query" => query}, socket) do
    tags =
      MyApp.Todos.Tag
      |> Ash.Query.filter(contains(name: ^query))
      |> MyApp.Todos.read!()

    options = Enum.map(tags, &{&1.name, &1.id})

    {:noreply, push_event(socket, "update_combobox_options", %{
      field: "tags",
      options: options
    })}
  end
  ```

  ### Creatable Combobox ⭐ NEW

  Allow creating new items on-the-fly.

  ```elixir
  field :tags do
    type :multiselect_combobox
    label "Tags"

    opts [
      creatable: true,              # ← Enable creating
      create_action: :create,
      create_label: "Create \"",
      search_event: "search_tags",
      debounce: 300,
      label_key: :name,
      value_key: :id
    ]
  end
  ```

  **LiveView Handler:**
  ```elixir
  def handle_event("create_combobox_item", %{
    "field" => "tags",
    "creatable_value" => tag_name
  }, socket) do
    case MyApp.Todos.create_tag(%{name: tag_name}) do
      {:ok, new_tag} ->
        # Add to current selection
        form = socket.assigns.form.source
        current_tags = AshPhoenix.Form.value(form, :tags) || []
        updated_tags = Enum.uniq(current_tags ++ [new_tag.id])
        form = AshPhoenix.Form.validate(form, %{tags: updated_tags})
        {:noreply, assign(socket, form: to_form(form))}

      {:error, changeset} ->
        {:noreply, put_flash(socket, :error, "Could not create tag")}
    end
  end
  ```

  ---

  ## Nested Forms

  For `has_many` relationships.

  ### Basic Nested Form

  ```elixir
  nested :subtasks do
    label "Subtasks"
    cardinality :many
    add_label "Add Subtask"
    remove_label "Remove"

    field :title do
      label "Subtask"
      required true
    end

    field :description do
      label "Notes"
      type :textarea
      rows 2
    end

    field :completed do
      label "Done"
      type :checkbox
    end
  end
  ```

  ### Nested Form Options

  | Option | Type | Default | Description |
  |--------|------|---------|-------------|
  | `:label` | String | - | Fieldset legend |
  | `:cardinality` | Atom | `:many` | `:many` or `:one` |
  | `:add_label` | String | `"Add"` | Add button text |
  | `:remove_label` | String | `"Remove"` | Remove button text |
  | `:class` | String | - | Fieldset CSS class |
  | `:create_action` | Atom | `:create` | Nested create action |
  | `:update_action` | Atom | `:update` | Nested update action |

  ---

  ## Field Options Reference

  ### Common Options

  | Option | Type | Description | Example |
  |--------|------|-------------|---------|
  | `:label` | String | Field label | `label "Title"` |
  | `:type` | Atom | UI type override | `type :textarea` |
  | `:placeholder` | String | Placeholder text | `placeholder "Enter..."` |
  | `:required` | Boolean | Show required indicator | `required true` |
  | `:hint` | String | Helper text | `hint "Keep it short"` |
  | `:class` | String | Input CSS class | `class "input-lg"` |
  | `:wrapper_class` | String | Wrapper CSS class | `wrapper_class "mb-4"` |
  | `:options` | List | Select options | `options: [{"A", :a}]` |
  | `:opts` | Keyword | Custom options | `opts [debounce: 300]` |

  ### Combobox Opts

  | Option | Type | Default | Description |
  |--------|------|---------|-------------|
  | `:search_event` | String | - | LiveView search event |
  | `:search_param` | String | `"query"` | Query param name |
  | `:debounce` | Integer | `300` | Debounce in ms |
  | `:label_key` | Atom | `:name` | Field for labels |
  | `:value_key` | Atom | `:id` | Field for values |
  | `:preload_options` | List | `[]` | Preloaded options |
  | `:creatable` | Boolean | `false` | Allow creating |
  | `:create_action` | Atom | `:create` | Create action name |
  | `:create_label` | String | `"Create \"\""` | Create button label |

  ---

  ## Examples

  ### Complete Form Example

  ```elixir
  defmodule MyApp.Todos.Task do
    form do
      action :create
      submit_label "Create Task"

      field :title do
        label "Task Title"
        placeholder "What needs to be done?"
        required true
        hint "Be specific"
      end

      field :description do
        label "Description"
        type :textarea
        rows 4
        placeholder "Add details..."
      end

      field :priority do
        label "Priority"
        type :select
        options: [
          {"Low", :low},
          {"Medium", :medium},
          {"High", :high}
        ]
        default :medium
      end

      field :due_date do
        label "Due Date"
        type :date
        hint "When should this be completed?"
      end

      field :assignees do
        type :multiselect_combobox
        label "Assignees"

        opts [
          search_event: "search_users",
          debounce: 300,
          label_key: :name,
          value_key: :id
        ]
      end

      field :tags do
        type :multiselect_combobox
        label "Tags"

        opts [
          creatable: true,
          create_action: :create,
          create_label: "Create \"",
          search_event: "search_tags"
        ]
      end

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
  end
  ```

  ---

  ## Getting Help

  - 📚 [Customization Guide](AshFormBuilder.Guide.Customization.html)
  - 📚 [Installation Guide](AshFormBuilder.Guide.Installation.html)
  - 💬 [Ash Framework Discord](https://discord.gg/ash-framework)
  """
end
