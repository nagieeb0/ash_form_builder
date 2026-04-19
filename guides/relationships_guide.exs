# =============================================================================
# ASH FORM BUILDER - RELATIONSHIPS GUIDE
# =============================================================================
# has_many vs many_to_many: Dynamic forms, filtering, and conditions
# =============================================================================

# =============================================================================
# PART 1: HAS_MANY (Nested Forms - Dynamic Add/Remove)
# =============================================================================
#
# Use `has_many` when:
# - Child records have their own lifecycle
# - You need to manage child attributes (not just the relationship)
# - Examples: Task → Subtasks, Order → OrderItems, Post → Comments
#
# =============================================================================

defmodule MyApp.Todos.Task do
  use Ash.Resource,
    domain: MyApp.Todos,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshFormBuilder]

  attributes do
    uuid_primary_key :id
    attribute :title, :string, allow_nil?: false
    attribute :status, :atom, constraints: [one_of: [:pending, :in_progress, :done]]
  end

  relationships do
    # ─────────────────────────────────────────────────────────────────────────
    # HAS_MANY: Subtasks
    # ─────────────────────────────────────────────────────────────────────────
    # Each subtask is a full record with its own attributes
    has_many :subtasks, MyApp.Todos.Subtask do
      destination_attribute_on_join_resource :task_id
      # Optionally set default on_create actions
    end

    # HAS_MANY: Checklists (another example)
    has_many :checklist_items, MyApp.Todos.ChecklistItem
  end

  actions do
    create :create do
      accept [:title, :status]
      # Manage nested records
      manage_relationship :subtasks, :subtasks, type: :create
      manage_relationship :checklist_items, :checklist_items, type: :create
    end

    update :update do
      accept [:title, :status]
      manage_relationship :subtasks, :subtasks, type: :create_and_destroy
      manage_relationship :checklist_items, :checklist_items, type: :create_and_destroy
    end
  end

  # ===========================================================================
  # FORM DSL - HAS_MANY WITH NESTED FORMS
  # ===========================================================================

  form do
    action :create

    field :title do
      label "Task Title"
      required true
    end

    field :status do
      type :select
      options: [{"Pending", :pending}, {"In Progress", :in_progress}, {"Done", :done}]
    end

    # ─────────────────────────────────────────────────────────────────────────
    # NESTED FORM: Subtasks (has_many)
    # ─────────────────────────────────────────────────────────────────────────
    #
    # Features:
    # - Dynamic add/remove buttons
    # - Each subtask is a full form with its own fields
    # - Can set min/max items
    # - Can pre-populate with existing records
    # ─────────────────────────────────────────────────────────────────────────

    nested :subtasks do
      label "Subtasks"
      cardinality :many  # ← :many = add/remove buttons, :one = single nested form

      # Button labels
      add_label "Add Subtask"
      remove_label "Remove"

      # Optional: Limit number of items
      # min_items 1       # ← At least 1 subtask required
      # max_items 10      # ← Maximum 10 subtasks

      # Optional: CSS customization
      # class "nested-subtasks border rounded p-4"

      # Subtask fields
      field :title do
        label "Subtask"
        placeholder "e.g., Research competitors"
        required true
      end

      field :description do
        label "Notes"
        type :textarea
        rows 2
      end

      field :completed do
        label "Done?"
        type :checkbox
      end

      field :priority do
        label "Priority"
        type :select
        options: [
          {"Low", :low},
          {"Medium", :medium},
          {"High", :high}
        ]
      end
    end

    # ─────────────────────────────────────────────────────────────────────────
    # NESTED FORM: Checklist Items (has_many - simple)
    # ─────────────────────────────────────────────────────────────────────────

    nested :checklist_items do
      label "Checklist"
      cardinality :many
      add_label "Add Item"

      field :text do
        label "Item"
        required true
      end

      field :checked do
        label "Checked"
        type :checkbox
      end
    end
  end
end

# ─────────────────────────────────────────────────────────────────────────────
# SUBTASK RESOURCE
# ─────────────────────────────────────────────────────────────────────────────

defmodule MyApp.Todos.Subtask do
  use Ash.Resource,
    domain: MyApp.Todos,
    data_layer: AshPostgres.DataLayer

  attributes do
    uuid_primary_key :id
    attribute :title, :string, allow_nil?: false
    attribute :description, :text
    attribute :completed, :boolean, default: false
    attribute :priority, :atom, constraints: [one_of: [:low, :medium, :high]]
    attribute :position, :integer, default: 0  # For ordering
  end

  relationships do
    belongs_to :task, MyApp.Todos.Task
  end

  actions do
    create :create do
      accept [:title, :description, :completed, :priority, :position]
    end

    update :update do
      accept [:title, :description, :completed, :priority, :position]
    end

    destroy :destroy do
      primary? true
    end
  end
end

# =============================================================================
# PART 2: MANY_TO_MANY (Combobox - Select from Existing)
# =============================================================================
#
# Use `many_to_many` when:
# - Linking to existing records
# - The related record has independent lifecycle
# - Examples: Task → Users (assignees), Task → Tags, Product → Categories
#
# =============================================================================

defmodule MyApp.Todos.Task do
  # ... (previous code)

  relationships do
    # ─────────────────────────────────────────────────────────────────────────
    # MANY_TO_MANY: Assignees (Users)
    # ─────────────────────────────────────────────────────────────────────────
    # Select from existing users, cannot create users from task form
    many_to_many :assignees, MyApp.Accounts.User do
      through MyApp.Todos.TaskAssignee
      source_attribute_on_join_resource :task_id
      destination_attribute_on_join_resource :user_id
    end

    # ─────────────────────────────────────────────────────────────────────────
    # MANY_TO_MANY: Tags (Creatable!)
    # ─────────────────────────────────────────────────────────────────────────
    # Select existing OR create new tags on-the-fly
    many_to_many :tags, MyApp.Todos.Tag do
      through MyApp.Todos.TaskTag
      source_attribute_on_join_resource :task_id
      destination_attribute_on_join_resource :tag_id
    end

    # ─────────────────────────────────────────────────────────────────────────
    # MANY_TO_MANY: Related Tasks
    # ─────────────────────────────────────────────────────────────────────────
    # Self-referential: tasks can link to other tasks
    many_to_many :related_tasks, MyApp.Todos.Task do
      through MyApp.Todos.TaskRelation
      source_attribute_on_join_resource :from_task_id
      destination_attribute_on_join_resource :to_task_id
    end
  end

  # ===========================================================================
  # FORM DSL - MANY_TO_MANY FIELDS
  # ===========================================================================

  form do
    action :create

    # ─────────────────────────────────────────────────────────────────────────
    # STANDARD COMBOBOX: Select from existing users
    # ─────────────────────────────────────────────────────────────────────────

    field :assignees do
      type :multiselect_combobox
      label "Assignees"
      placeholder "Search users..."

      opts [
        # Search event for LiveView handler
        search_event: "search_users",
        debounce: 300,

        # Field mappings
        label_key: :name,     # Display user.name
        value_key: :id,       # Use user.id as value

        # Optional: Preload options (for small datasets < 100)
        # preload_options: fn -> MyApp.Accounts.list_users() |> Enum.map(&{&1.name, &1.id}) end

        hint: "Who should work on this task?"
      ]
    end

    # ─────────────────────────────────────────────────────────────────────────
    # CREATABLE COMBOBOX: Tags (create on-the-fly)
    # ─────────────────────────────────────────────────────────────────────────

    field :tags do
      type :multiselect_combobox
      label "Tags"
      placeholder "Search or create tags..."

      opts [
        # ★ Enable creating new tags
        creatable: true,
        create_action: :create,
        create_label: "Create \"",

        search_event: "search_tags",
        debounce: 300,
        label_key: :name,
        value_key: :id,

        hint: "Add tags or create new ones instantly"
      ]
    end

    # ─────────────────────────────────────────────────────────────────────────
    # FILTERED COMBOBOX: Related Tasks
    # ─────────────────────────────────────────────────────────────────────────
    # Only show tasks that meet certain criteria

    field :related_tasks do
      type :multiselect_combobox
      label "Related Tasks"
      placeholder "Search tasks..."

      opts [
        search_event: "search_related_tasks",
        debounce: 300,
        label_key: :title,
        value_key: :id,

        # Pass metadata for filtering
        filter_params: [
          exclude_completed: true,
          exclude_self: true  # Don't show current task
        ],

        hint: "Link to related tasks"
      ]
    end
  end
end

# =============================================================================
# PART 3: LIVEVIEW - HANDLING SEARCH & FILTERING
# =============================================================================

defmodule MyAppWeb.TaskLive.Form do
  use MyAppWeb, :live_view

  alias MyApp.Todos
  alias MyApp.Todos.Task

  # ───────────────────────────────────────────────────────────────────────────
  # MOUNT - With Preloaded Options
  # ───────────────────────────────────────────────────────────────────────────

  def mount(%{"id" => id}, _session, socket) do
    # EDIT: Load existing task with relationships
    task = Todos.get_task!(id, load: [:assignees, :tags, :subtasks, :checklist_items])
    form = Task.Form.for_update(task, actor: socket.assigns.current_user)

    {:ok,
     socket
     |> assign(:form, form)
     |> assign(:task, task)
     # Preload some combobox options if needed
     |> assign(:user_options, load_user_options())}
  end

  def mount(_params, _session, socket) do
    # CREATE: New task
    form = Task.Form.for_create(actor: socket.assigns.current_user)

    {:ok,
     socket
     |> assign(:form, form)
     |> assign(:user_options, load_user_options())}
  end

  # ───────────────────────────────────────────────────────────────────────────
  # SEARCH HANDLERS - With Filtering Logic
  # ───────────────────────────────────────────────────────────────────────────

  @impl true
  def handle_event("search_users", %{"query" => query}, socket) do
    # FILTER: Only active users, search by name/email
    users =
      MyApp.Accounts.User
      |> Ash.Query.filter(status == :active)  # ← Condition 1
      |> Ash.Query.filter(contains(name: ^query) or contains(email: ^query))
      |> Ash.Query.limit(20)  # ← Limit results
      |> Todos.read!(actor: socket.assigns.current_user)

    options = Enum.map(users, &{&1.name, &1.id})

    {:noreply, push_event(socket, "update_combobox_options", %{
      field: "assignees",
      options: options
    })}
  end

  @impl true
  def handle_event("search_tags", %{"query" => query}, socket) do
    # For creatable combobox - search existing tags
    tags =
      MyApp.Todos.Tag
      |> Ash.Query.filter(contains(name: ^query))
      |> Ash.Query.limit(50)
      |> Todos.read!(actor: socket.assigns.current_user)

    options = Enum.map(tags, &{&1.name, &1.id})

    {:noreply, push_event(socket, "update_combobox_options", %{
      field: "tags",
      options: options
    })}
  end

  @impl true
  def handle_event("search_related_tasks", %{"query" => query, "filter_params" => filter_params}, socket) do
    # FILTER: Complex query with multiple conditions
    query_builder = MyApp.Todos.Task |> Ash.Query.filter(id != ^socket.assigns.task.id)

    # Apply filters from filter_params
    query_builder =
      if filter_params["exclude_completed"] == "true" do
        Ash.Query.filter(query_builder, status != :done)
      else
        query_builder
      end

    query_builder =
      if filter_params["exclude_self"] == "true" do
        Ash.Query.filter(query_builder, id != ^socket.assigns.task.id)
      else
        query_builder
      end

    # Search by title
    tasks =
      query_builder
      |> Ash.Query.filter(contains(title: ^query))
      |> Ash.Query.order_by(created_at: :desc)
      |> Ash.Query.limit(20)
      |> Todos.read!(actor: socket.assigns.current_user)

    options = Enum.map(tasks, &{&1.title, &1.id})

    {:noreply, push_event(socket, "update_combobox_options", %{
      field: "related_tasks",
      options: options
    })}
  end

  # ───────────────────────────────────────────────────────────────────────────
  # CREATE NEW ITEM (Creatable Combobox)
  # ───────────────────────────────────────────────────────────────────────────

  @impl true
  def handle_event("create_combobox_item", %{
    "field" => "tags",
    "creatable_value" => tag_name
  }, socket) do
    # Create new tag on-the-fly
    case Todos.create_tag(%{name: tag_name}, actor: socket.assigns.current_user) do
      {:ok, new_tag} ->
        # Add to current selection
        form = socket.assigns.form.source
        current_tags = AshPhoenix.Form.value(form, :tags) || []
        updated_tags = Enum.uniq(current_tags ++ [new_tag.id])

        form = AshPhoenix.Form.validate(form, %{tags: updated_tags})

        {:noreply, assign(socket, form: to_form(form))}

      {:error, changeset} ->
        # Handle error (e.g., duplicate name)
        {:noreply, put_flash(socket, :error, "Could not create tag: #{inspect(changeset.errors)}")}
    end
  end

  # ───────────────────────────────────────────────────────────────────────────
  # SUCCESS HANDLER
  # ───────────────────────────────────────────────────────────────────────────

  @impl true
  def handle_info({:form_submitted, Task, task}, socket) do
    {:noreply,
     socket
     |> put_flash(:info, "Task saved successfully!")
     |> push_navigate(to: ~p"/tasks/#{task.id}")}
  end

  # ───────────────────────────────────────────────────────────────────────────
  # HELPERS
  # ───────────────────────────────────────────────────────────────────────────

  defp load_user_options do
    # Preload active users for small teams
    MyApp.Accounts.User
    |> Ash.Query.filter(status == :active)
    |> Ash.Query.limit(100)
    |> Todos.read!()
    |> Enum.map(&{&1.name, &1.id})
  end
end

# =============================================================================
# PART 4: ADVANCED - CONDITIONAL & DYNAMIC BEHAVIOR
# =============================================================================

# ─────────────────────────────────────────────────────────────────────────────
# 4.1 CONDITIONAL NESTED FORMS
# ─────────────────────────────────────────────────────────────────────────────
# Show/hide nested forms based on parent field value

defmodule MyApp.Todos.Project do
  use Ash.Resource,
    domain: MyApp.Todos,
    extensions: [AshFormBuilder]

  attributes do
    uuid_primary_key :id
    attribute :name, :string, allow_nil?: false
    attribute :type, :atom, constraints: [one_of: [:simple, :complex]]
  end

  relationships do
    has_many :phases, MyApp.Todos.Phase
    has_many :tasks, MyApp.Todos.Task
  end

  actions do
    create :create do
      accept [:name, :type]
      manage_relationship :phases, :phases, type: :create
      manage_relationship :tasks, :tasks, type: :create
    end
  end

  form do
    action :create

    field :name do
      label "Project Name"
      required true
    end

    field :type do
      label "Project Type"
      type :select
      options: [
        {"Simple (No Phases)", :simple},
        {"Complex (With Phases)", :complex}
      ]
      # This will trigger conditional rendering in LiveView
      phx_change: "type_changed"
    end

    # ────────────────────────────────────────────────────────────────────────
    # CONDITIONAL: Only show phases for complex projects
    # ────────────────────────────────────────────────────────────────────────
    #
    # In LiveView, you can conditionally render:
    #
    # <%= if @form.source.data.type == :complex do %>
    #   <.nested_form :for={phase <- @form[:phases]} ... />
    # <% end %>
    #
    # Or use phx-change to show/hide dynamically

    nested :phases do
      label "Project Phases"
      cardinality :many

      field :name do
        label "Phase Name"
        required true
      end

      field :order do
        label "Order"
        type :number
      end
    end
  end
end

# ─────────────────────────────────────────────────────────────────────────────
# 4.2 DYNAMIC LIMITS - Min/Max Nested Items
# ─────────────────────────────────────────────────────────────────────────────

defmodule MyApp.Todos.Event do
  use Ash.Resource,
    domain: MyApp.Todos,
    extensions: [AshFormBuilder]

  attributes do
    uuid_primary_key :id
    attribute :name, :string, allow_nil?: false
  end

  relationships do
    has_many :speakers, MyApp.Todos.Speaker
  end

  form do
    action :create

    field :name do
      label "Event Name"
      required true
    end

    # ────────────────────────────────────────────────────────────────────────
    # NESTED WITH LIMITS
    # ────────────────────────────────────────────────────────────────────────

    nested :speakers do
      label "Speakers"
      cardinality :many

      # ★ Enforce minimum 1 speaker
      # Note: You'll need to validate this in your action
      # validate present(:speakers) or length(:speakers) >= 1

      # ★ Hide add button after max reached
      # In LiveView:
      # <%= if length(@form[:speakers].value) < 5 do %>
      #   <button phx-click="add_form">Add Speaker</button>
      # <% end %>

      field :name do
        label "Speaker Name"
        required true
      end

      field :title do
        label "Title"
        placeholder "e.g., CEO at Acme Corp"
      end
    end
  end
end

# ─────────────────────────────────────────────────────────────────────────────
# 4.3 FILTERED OPTIONS - Query-Based Limiting
# ─────────────────────────────────────────────────────────────────────────────

defmodule MyApp.Todos.Meeting do
  use Ash.Resource,
    domain: MyApp.Todos,
    extensions: [AshFormBuilder]

  attributes do
    uuid_primary_key :id
    attribute :title, :string, allow_nil?: false
    attribute :meeting_type, :atom, constraints: [one_of: [:internal, :external, :all_hands]]
  end

  relationships do
    # Only show users from same organization
    many_to_many :attendees, MyApp.Accounts.User do
      through MyApp.Todos.MeetingAttendee
    end

    # Only show rooms that are available
    many_to_many :rooms, MyApp.Resources.Room do
      through MyApp.Todos.MeetingRoom
    end
  end

  form do
    action :create

    field :title do
      label "Meeting Title"
      required true
    end

    field :meeting_type do
      label "Meeting Type"
      type :select
      options: [
        {"Internal", :internal},
        {"External", :external},
        {"All Hands", :all_hands}
      ]
      # Trigger filter update when changed
      phx_change: "meeting_type_changed"
    end

    # ────────────────────────────────────────────────────────────────────────
    # FILTERED: Attendees by organization
    # ────────────────────────────────────────────────────────────────────────

    field :attendees do
      type :multiselect_combobox
      label "Attendees"
      placeholder "Search attendees..."

      opts [
        search_event: "search_attendees",
        debounce: 300,
        label_key: :name,
        value_key: :id,
        # Pass filter params to search handler
        filter_params: [
          organization_id: :current_user_org,  # Special value resolved in LiveView
          active_only: true
        ]
      ]
    end

    # ────────────────────────────────────────────────────────────────────────
    # FILTERED: Rooms by capacity and availability
    # ────────────────────────────────────────────────────────────────────────

    field :rooms do
      type :multiselect_combobox
      label "Rooms"
      placeholder "Search rooms..."

      opts [
        search_event: "search_rooms",
        debounce: 300,
        label_key: :name,
        value_key: :id,
        filter_params: [
          min_capacity: 10,  # Could be dynamic based on attendee count
          available: true
        ]
      ]
    end
  end
end

# LiveView handler for filtered attendees
defmodule MyAppWeb.MeetingLive.Form do
  use MyAppWeb, :live_view

  @impl true
  def handle_event("search_attendees", %{"query" => query}, socket) do
    # Get current user's organization
    current_user = socket.assigns.current_user
    org_id = current_user.organization_id

    # Filter by organization and active status
    users =
      MyApp.Accounts.User
      |> Ash.Query.filter(organization_id == ^org_id)
      |> Ash.Query.filter(status == :active)
      |> Ash.Query.filter(contains(name: ^query) or contains(email: ^query))
      |> Ash.Query.limit(50)
      |> MyApp.Accounts.read!()

    options = Enum.map(users, &{&1.name, &1.id})

    {:noreply, push_event(socket, "update_combobox_options", %{
      field: "attendees",
      options: options
    })}
  end

  @impl true
  def handle_event("search_rooms", %{"query" => query}, socket) do
    # Get filter params from form
    # In real app, calculate based on attendee count
    min_capacity = 10

    rooms =
      MyApp.Resources.Room
      |> Ash.Query.filter(capacity >= ^min_capacity)
      |> Ash.Query.filter(available == true)
      |> Ash.Query.filter(contains(name: ^query))
      |> Ash.Query.limit(20)
      |> MyApp.Resources.read!()

    options = Enum.map(rooms, &{&1.name, &1.id})

    {:noreply, push_event(socket, "update_combobox_options", %{
      field: "rooms",
      options: options
    })}
  end
end

# ─────────────────────────────────────────────────────────────────────────────
# 4.4 DYNAMIC PRELOADING - Load Options on Mount
# ─────────────────────────────────────────────────────────────────────────────

defmodule MyAppWeb.TaskLive.Form do
  use MyAppWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    form = Task.Form.for_create(actor: socket.assigns.current_user)

    # Preload options for small datasets
    # This avoids initial empty combobox
    {:ok,
     socket
     |> assign(:form, form)
     |> assign(:initial_tag_options, preload_tags(""))
     |> assign(:initial_user_options, preload_active_users(""))}
  end

  @impl true
  def handle_event("search_tags", %{"query" => query}, socket) do
    # For creatable combobox, always allow creating even if no results
    tags = preload_tags(query)
    options = Enum.map(tags, &{&1.name, &1.id})

    {:noreply, push_event(socket, "update_combobox_options", %{
      field: "tags",
      options: options,
      # Tell frontend this is creatable
      creatable: true
    })}
  end

  defp preload_tags(query) do
    MyApp.Todos.Tag
    |> Ash.Query.filter(contains(name: ^query))
    |> Ash.Query.limit(50)
    |> MyApp.Todos.read!()
  end

  defp preload_active_users(query) do
    MyApp.Accounts.User
    |> Ash.Query.filter(status == :active)
    |> Ash.Query.filter(contains(name: ^query))
    |> Ash.Query.limit(100)
    |> MyApp.Accounts.read!()
  end
end

# =============================================================================
# PART 5: SUMMARY - HAS_MANY vs MANY_TO_MANY
# =============================================================================
#
# ┌─────────────────────────────────────────────────────────────────────────┐
# │ HAS_MANY (Nested Forms)                                                 │
# ├─────────────────────────────────────────────────────────────────────────┤
# │ • Child records have independent lifecycle                             │
# │ • You manage child attributes in the form                              │
# │ • Dynamic add/remove with nested forms                                 │
# │ • Examples: Subtasks, OrderItems, Comments                             │
# │                                                                         │
# │ Usage:                                                                  │
# │   nested :subtasks do                                                   │
# │     cardinality :many                                                   │
# │     field :title, required: true                                        │
# │   end                                                                   │
# └─────────────────────────────────────────────────────────────────────────┘
#
# ┌─────────────────────────────────────────────────────────────────────────┐
# │ MANY_TO_MANY (Combobox)                                                 │
# ├─────────────────────────────────────────────────────────────────────────┤
# │ • Link to existing independent records                                 │
# │ • Select from searchable dropdown                                      │
# │ • Can be creatable (create on-the-fly)                                 │
# │ • Examples: Tags, Assignees, Categories                                │
# │                                                                         │
# │ Usage:                                                                  │
# │   field :tags do                                                        │
# │     type :multiselect_combobox                                          │
# │     opts [creatable: true, search_event: "search_tags"]                 │
# │   end                                                                   │
# └─────────────────────────────────────────────────────────────────────────┘
#
# ┌─────────────────────────────────────────────────────────────────────────┐
# │ FILTERING & LIMITING                                                    │
# ├─────────────────────────────────────────────────────────────────────────┤
# │ • Search handlers filter results via Ash.Query                         │
# │ • Pass filter_params through combobox opts                             │
# │ • Limit results with Ash.Query.limit()                                 │
# │ • Conditional rendering in LiveView based on field values              │
# │ • Min/max items enforced in UI and validated in actions                │
# └─────────────────────────────────────────────────────────────────────────┘
#
# =============================================================================
# END OF RELATIONSHIPS GUIDE
# =============================================================================
