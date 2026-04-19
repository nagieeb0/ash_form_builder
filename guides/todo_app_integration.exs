# =============================================================================
# ASH FORM BUILDER - TODO APP INTEGRATION GUIDE
# =============================================================================
# Complete step-by-step guide: From mix.exs to LiveView CRUD
# =============================================================================

# =============================================================================
# STEP 1: ADD DEPENDENCIES (mix.exs)
# =============================================================================

defmodule TodoApp.MixProject do
  use Mix.Project

  def project do
    [
      app: :todo_app,
      version: "0.1.0",
      elixir: "~> 1.17",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  def application do
    [
      mod: {TodoApp.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      # Core Ash Framework
      {:ash, "~> 3.0"},
      {:ash_phoenix, "~> 2.0"},
      {:ash_postgres, "~> 2.0"},
      
      # Phoenix
      {:phoenix, "~> 1.7.14"},
      {:phoenix_html, "~> 4.0"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 1.0.0"},
      {:floki, ">= 0.30.0", only: :test},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      
      # ASH FORM BUILDER ⭐
      {:ash_form_builder, path: "../ash_form_builder"},  # Local path
      # OR from git: {:ash_form_builder, git: "https://github.com/nagieeb0/ash_form_builder.git"},
      # OR from hex (when published): {:ash_form_builder, "~> 0.1.0"}
      
      # UI Components (Optional - for MishkaTheme)
      {:mishka_chelekom, "~> 0.0.8"},
      
      # Database
      {:ecto_sql, "~> 3.10"},
      {:postgrex, ">= 0.0.0"},
      
      # Other
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.20"},
      {:jason, "~> 1.2"},
      {:dns_cluster, "~> 0.1.1"},
      {:bandit, "~> 1.5"}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end

# =============================================================================
# STEP 2: CONFIGURATION (config/config.exs)
# =============================================================================

import Config

# Configure AshFormBuilder theme
config :ash_form_builder, :theme, AshFormBuilder.Theme.MishkaTheme
# OR use default: config :ash_form_builder, :theme, AshFormBuilder.Themes.Default

# Configure Ash
config :ash, :include_embedded_source_by_default?, true

# Configure your endpoint
config :todo_app, TodoAppWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: TodoAppWeb.ErrorHTML, json: TodoAppWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: TodoApp.PubSub,
  live_view: [signing_salt: "your-signing-salt"]

# Configure your Repo
config :todo_app, TodoApp.Repo,
  database: Path.expand("../todo_app_dev.db", Path.dirname(__ENV__.file)),
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10,
  pool: Ecto.Adapters.SQL.Sandbox

# Configure Ash domains
config :todo_app, ash_domains: [TodoApp.Todos]

# =============================================================================
# STEP 3: ASH DOMAIN (lib/todo_app/todos.ex)
# =============================================================================

defmodule TodoApp.Todos do
  @moduledoc """
  Todos domain - manages tasks, categories, and tags.
  
  ## Code Interfaces
  
  This domain generates form helper functions via `define :form_to_*`:
  
  - `TodoApp.Todos.Task.Form.for_create/1`
  - `TodoApp.Todos.Task.Form.for_update/2`
  
  These helpers integrate seamlessly with AshFormBuilder.
  """

  use Ash.Domain

  resources do
    # Task resource with form code interfaces
    resource TodoApp.Todos.Task do
      # Standard CRUD
      define :list_tasks, action: :read
      define :get_task, action: :read, get_by: [:id]
      define :destroy_task, action: :destroy
      
      # ⭐ Form Code Interfaces - generates Form helpers
      define :form_to_create_task, action: :create
      define :form_to_update_task, action: :update
    end

    # Category resource
    resource TodoApp.Todos.Category do
      define :list_categories, action: :read
      define :search_categories, action: :read
      define :form_to_create_category, action: :create
    end

    # Tag resource (creatable on-the-fly)
    resource TodoApp.Todos.Tag do
      define :list_tags, action: :read
      define :search_tags, action: :read
      define :form_to_create_tag, action: :create
    end
  end
end

# =============================================================================
# STEP 4: ASH RESOURCES
# =============================================================================

# ─────────────────────────────────────────────────────────────────────────────
# 4.1 TASK RESOURCE (Main Todo Item)
# ─────────────────────────────────────────────────────────────────────────────

defmodule TodoApp.Todos.Task do
  @moduledoc """
  Task resource - represents a single todo item.
  
  Features:
  - Title, description, due date
  - Priority and status enums
  - Many-to-many with Categories
  - Many-to-many with Tags (creatable!)
  """

  use Ash.Resource,
    domain: TodoApp.Todos,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshFormBuilder]  # ⭐ Required for AshFormBuilder

  postgres do
    table "tasks"
    repo TodoApp.Repo
  end

  # ───────────────────────────────────────────────────────────────────────────
  # Attributes
  # ───────────────────────────────────────────────────────────────────────────

  attributes do
    uuid_primary_key :id

    attribute :title, :string do
      allow_nil? false
      constraints min_length: 1, max_length: 200
    end

    attribute :description, :text do
      allow_nil? true
    end

    attribute :completed, :boolean do
      default false
    end

    attribute :priority, :atom do
      constraints one_of: [:low, :medium, :high, :urgent]
      default :medium
    end

    attribute :status, :atom do
      constraints one_of: [:pending, :in_progress, :done]
      default :pending
    end

    attribute :due_date, :date do
      allow_nil? true
    end

    timestamps()
  end

  # ───────────────────────────────────────────────────────────────────────────
  # Relationships
  # ───────────────────────────────────────────────────────────────────────────

  relationships do
    # Many-to-many with Categories (select from existing)
    many_to_many :categories, TodoApp.Todos.Category do
      through TodoApp.Todos.TaskCategory
      source_attribute_on_join_resource :task_id
      destination_attribute_on_join_resource :category_id
    end

    # Many-to-many with Tags (creatable on-the-fly!)
    many_to_many :tags, TodoApp.Todos.Tag do
      through TodoApp.Todos.TaskTag
      source_attribute_on_join_resource :task_id
      destination_attribute_on_join_resource :tag_id
    end
  end

  # ───────────────────────────────────────────────────────────────────────────
  # Actions
  # ───────────────────────────────────────────────────────────────────────────

  actions do
    defaults [:read]

    create :create do
      accept [:title, :description, :completed, :priority, :status, :due_date]
      # Manage relationships
      manage_relationship :categories, :categories, type: :append_and_remove
      manage_relationship :tags, :tags, type: :append_and_remove
    end

    update :update do
      accept [:title, :description, :completed, :priority, :status, :due_date]
      manage_relationship :categories, :categories, type: :append_and_remove
      manage_relationship :tags, :tags, type: :append_and_remove
    end

    destroy :destroy do
      primary? true
      require_atomic? false
    end
  end

  # ───────────────────────────────────────────────────────────────────────────
  # Validations
  # ───────────────────────────────────────────────────────────────────────────

  validations do
    validate present([:title])
    validate string_length(:title, min: 1, max: 200)
    validate expression(:due_date, fn task, _ ->
      if task.due_date && Date.compare(task.due_date, Date.utc_today()) == :lt do
        {:error, "due date cannot be in the past"}
      else
        :ok
      end
    end)
  end

  # ───────────────────────────────────────────────────────────────────────────
  # Policies
  # ───────────────────────────────────────────────────────────────────────────

  policies do
    policy action_type(:create) do
      authorize_if actor_present()
    end

    policy action_type(:update) do
      authorize_if actor_present()
    end

    policy action_type(:destroy) do
      authorize_if actor_present()
    end

    policy action_type(:read) do
      authorize_if always()
    end
  end

  # ===========================================================================
  # ASH FORM BUILDER DSL - Form Configuration
  # ===========================================================================

  form do
    action :create
    submit_label "Create Task"
    wrapper_class "space-y-6"

    # ────────────────────────────────────────────────────────────────────────
    # Standard Fields
    # ────────────────────────────────────────────────────────────────────────

    field :title do
      label "Task Title"
      placeholder "e.g., Complete project documentation"
      required true
      hint "Keep it concise but descriptive"
    end

    field :description do
      label "Description"
      type :textarea
      placeholder "Add any additional details..."
      rows 4
      hint "Optional: Add more context about this task"
    end

    field :priority do
      label "Priority"
      type :select
      options [
        {"Low", :low},
        {"Medium", :medium},
        {"High", :high},
        {"Urgent", :urgent}
      ]
      hint "How important is this task?"
    end

    field :status do
      label "Status"
      type :select
      options [
        {"Pending", :pending},
        {"In Progress", :in_progress},
        {"Done", :done}
      ]
    end

    field :due_date do
      label "Due Date"
      type :date
      hint "When should this be completed?"
    end

    field :completed do
      label "Completed"
      type :checkbox
      hint "Mark as complete"
    end

    # ────────────────────────────────────────────────────────────────────────
    # Many-to-Many: Categories (NON-CREATABLE)
    # ────────────────────────────────────────────────────────────────────────
    # Users can only select from existing categories

    field :categories do
      type :multiselect_combobox
      label "Categories"
      placeholder "Search categories..."
      required false

      opts [
        search_event: "search_categories",
        debounce: 300,
        label_key: :name,
        value_key: :id,
        hint: "Organize your task into categories"
      ]
    end

    # ────────────────────────────────────────────────────────────────────────
    # Many-to-Many: Tags (CREATABLE!) ⭐
    # ────────────────────────────────────────────────────────────────────────
    # Users can create new tags on-the-fly

    field :tags do
      type :multiselect_combobox
      label "Tags"
      placeholder "Search or create tags..."
      required false

      opts [
        # ★ Enable creatable functionality
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
  end
end

# ─────────────────────────────────────────────────────────────────────────────
# 4.2 CATEGORY RESOURCE
# ─────────────────────────────────────────────────────────────────────────────

defmodule TodoApp.Todos.Category do
  @moduledoc "Category for organizing tasks (e.g., Work, Personal, Shopping)"

  use Ash.Resource,
    domain: TodoApp.Todos,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "categories"
    repo TodoApp.Repo
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      allow_nil? false
      unique true
    end

    attribute :color, :string do
      default "blue"
      constraints one_of: ["red", "blue", "green", "yellow", "purple", "orange"]
    end

    attribute :icon, :string do
      allow_nil? true
    end

    timestamps()
  end

  relationships do
    many_to_many :tasks, TodoApp.Todos.Task do
      through TodoApp.Todos.TaskCategory
      source_attribute_on_join_resource :category_id
      destination_attribute_on_join_resource :task_id
    end
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [:name, :color, :icon]
    end

    update :update do
      accept [:name, :color, :icon]
    end
  end

  validations do
    validate present([:name])
  end
end

# ─────────────────────────────────────────────────────────────────────────────
# 4.3 TAG RESOURCE (Creatable On-the-Fly)
# ─────────────────────────────────────────────────────────────────────────────

defmodule TodoApp.Todos.Tag do
  @moduledoc "Tag for labeling tasks (e.g., #urgent, #waiting, #5min)"

  use Ash.Resource,
    domain: TodoApp.Todos,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "tags"
    repo TodoApp.Repo
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      allow_nil? false
      unique true
    end

    timestamps()
  end

  relationships do
    many_to_many :tasks, TodoApp.Todos.Task do
      through TodoApp.Todos.TaskTag
      source_attribute_on_join_resource :tag_id
      destination_attribute_on_join_resource :task_id
    end
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [:name]
    end

    update :update do
      accept [:name]
    end
  end

  validations do
    validate present([:name])
    validate string_length(:name, min: 1, max: 50)
  end
end

# ─────────────────────────────────────────────────────────────────────────────
# 4.4 JOIN RESOURCES
# ─────────────────────────────────────────────────────────────────────────────

defmodule TodoApp.Todos.TaskCategory do
  use Ash.Resource,
    domain: TodoApp.Todos,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "tasks_categories"
    repo TodoApp.Repo
  end

  attributes do
    uuid_primary_key :id
    attribute :task_id, :uuid, allow_nil?: false
    attribute :category_id, :uuid, allow_nil?: false
  end

  relationships do
    belongs_to :task, TodoApp.Todos.Task
    belongs_to :category, TodoApp.Todos.Category
  end
end

defmodule TodoApp.Todos.TaskTag do
  use Ash.Resource,
    domain: TodoApp.Todos,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "tasks_tags"
    repo TodoApp.Repo
  end

  attributes do
    uuid_primary_key :id
    attribute :task_id, :uuid, allow_nil?: false
    attribute :tag_id, :uuid, allow_nil?: false
  end

  relationships do
    belongs_to :task, TodoApp.Todos.Task
    belongs_to :tag, TodoApp.Todos.Tag
  end
end

# =============================================================================
# STEP 5: PHOENIX LIVEVIEW - TASK FORM
# =============================================================================

defmodule TodoAppWeb.TaskLive.Form do
  @moduledoc """
  LiveView for creating and updating tasks.
  
  Features:
  - Zero manual AshPhoenix.Form calls
  - Automatic form generation via AshFormBuilder
  - Searchable combobox for categories
  - Creatable combobox for tags
  - Real-time validation
  """

  use TodoAppWeb, :live_view

  alias TodoApp.Todos
  alias TodoApp.Todos.Task

  # ───────────────────────────────────────────────────────────────────────────
  # MOUNT - Initialize Form
  # ───────────────────────────────────────────────────────────────────────────

  @impl true
  def mount(%{"id" => id} = _params, _session, socket) do
    # EDIT MODE: Update existing task
    task = Todos.get_task!(id, load: [:categories, :tags], actor: socket.assigns.current_user)
    
    form = Task.Form.for_update(task, actor: socket.assigns.current_user)

    {:ok,
     socket
     |> assign(:page_title, "Edit Task")
     |> assign(:form, form)
     |> assign(:task, task)
     |> assign(:mode, :edit)
     |> assign(:category_options, load_options(task.categories))
     |> assign(:tag_options, load_options(task.tags))}
  end

  def mount(_params, _session, socket) do
    # CREATE MODE: New task
    form = Task.Form.for_create(actor: socket.assigns.current_user)

    {:ok,
     socket
     |> assign(:page_title, "New Task")
     |> assign(:form, form)
     |> assign(:task, nil)
     |> assign(:mode, :create)
     |> assign(:category_options, [])
     |> assign(:tag_options, [])}
  end

  # ───────────────────────────────────────────────────────────────────────────
  # RENDER - Form UI
  # ───────────────────────────────────────────────────────────────────────────

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto px-4 py-8">
      <h1 class="text-3xl font-bold mb-6 text-gray-900"><%= @page_title %></h1>

      <div class="bg-white rounded-lg shadow-md p-6">
        <%!--
          AshFormBuilder.FormComponent:
          - Renders all fields from the form DSL
          - Uses configured theme (MishkaTheme)
          - Handles validation errors
          - Manages combobox search & create events
        --%>
        <.live_component
          module={AshFormBuilder.FormComponent}
          id="task-form"
          resource={Task}
          form={@form}
        />
      </div>

      <div class="mt-6 flex justify-between">
        <.link
          href={~p"/tasks"}
          class="text-gray-600 hover:text-gray-900"
        >
          ← Back to Tasks
        </.link>
      </div>
    </div>
    """
  end

  # ───────────────────────────────────────────────────────────────────────────
  # SEARCH HANDLERS - Combobox
  # ───────────────────────────────────────────────────────────────────────────

  @impl true
  def handle_event("search_categories", %{"query" => query}, socket) do
    categories =
      TodoApp.Todos.Category
      |> Ash.Query.filter(contains(name: ^query))
      |> Todos.read!(actor: socket.assigns.current_user)

    options = Enum.map(categories, &{&1.name, &1.id})

    {:noreply, push_event(socket, "update_combobox_options", %{
      field: "categories",
      options: options
    })}
  end

  @impl true
  def handle_event("search_tags", %{"query" => query}, socket) do
    # For creatable combobox - search existing tags
    # Users can still create new ones via the create button
    tags =
      TodoApp.Todos.Tag
      |> Ash.Query.filter(contains(name: ^query))
      |> Todos.read!(actor: socket.assigns.current_user)

    options = Enum.map(tags, &{&1.name, &1.id})

    {:noreply, push_event(socket, "update_combobox_options", %{
      field: "tags",
      options: options
    })}
  end

  # ───────────────────────────────────────────────────────────────────────────
  # SUCCESS HANDLER - Form Submission
  # ───────────────────────────────────────────────────────────────────────────

  @impl true
  def handle_info({:form_submitted, Task, task}, socket) do
    message = case socket.assigns.mode do
      :create -> "Task created successfully! 🎉"
      :update -> "Task updated successfully! ✅"
    end

    {:noreply,
     socket
     |> put_flash(:info, message)
     |> push_navigate(to: ~p"/tasks/#{task.id}")}
  end

  # ───────────────────────────────────────────────────────────────────────────
  # PRIVATE HELPERS
  # ───────────────────────────────────────────────────────────────────────────

  defp load_options(records) do
    Enum.map(records, &{&1.name, &1.id})
  end
end

# =============================================================================
# STEP 6: PHOENIX LIVEVIEW - TASK INDEX (List View)
# =============================================================================

defmodule TodoAppWeb.TaskLive.Index do
  @moduledoc "Lists all tasks with create button"

  use TodoAppWeb, :live_view

  alias TodoApp.Todos
  alias TodoApp.Todos.Task

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :tasks, Todos.list_tasks())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-6xl mx-auto px-4 py-8">
      <div class="flex justify-between items-center mb-6">
        <h1 class="text-3xl font-bold text-gray-900">Tasks</h1>
        <.link
          href={~p"/tasks/new"}
          class="bg-blue-600 text-white px-4 py-2 rounded-md hover:bg-blue-700"
        >
          + New Task
        </.link>
      </div>

      <div class="bg-white rounded-lg shadow overflow-hidden">
        <table class="min-w-full divide-y divide-gray-200">
          <thead class="bg-gray-50">
            <tr>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Title</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Priority</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Status</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Due Date</th>
              <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase">Actions</th>
            </tr>
          </thead>
          <tbody class="bg-white divide-y divide-gray-200" id="tasks" phx-update="stream">
            <tr :for={{id, task} <- @streams.tasks} class="hover:bg-gray-50">
              <td class="px-6 py-4 whitespace-nowrap">
                <div class="text-sm font-medium text-gray-900"><%= task.title %></div>
              </td>
              <td class="px-6 py-4 whitespace-nowrap">
                <span class={priority_class(task.priority)}>
                  <%= String.capitalize(to_string(task.priority)) %>
                </span>
              </td>
              <td class="px-6 py-4 whitespace-nowrap">
                <span class={status_class(task.status)}>
                  <%= String.capitalize(to_string(task.status)) %>
                </span>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                <%= if task.due_date, do: task.due_date, else: "-" %>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                <.link href={~p"/tasks/#{task.id}"} class="text-blue-600 hover:text-blue-900 mr-3">
                  View
                </.link>
                <.link href={~p"/tasks/#{task.id}/edit"} class="text-green-600 hover:text-green-900">
                  Edit
                </.link>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
    """
  end

  defp priority_class(:urgent), do: "px-2 py-1 text-xs rounded-full bg-red-100 text-red-800"
  defp priority_class(:high), do: "px-2 py-1 text-xs rounded-full bg-orange-100 text-orange-800"
  defp priority_class(:medium), do: "px-2 py-1 text-xs rounded-full bg-yellow-100 text-yellow-800"
  defp priority_class(:low), do: "px-2 py-1 text-xs rounded-full bg-green-100 text-green-800"

  defp status_class(:done), do: "px-2 py-1 text-xs rounded-full bg-green-100 text-green-800"
  defp status_class(:in_progress), do: "px-2 py-1 text-xs rounded-full bg-blue-100 text-blue-800"
  defp status_class(:pending), do: "px-2 py-1 text-xs rounded-full bg-gray-100 text-gray-800"
end

# =============================================================================
# STEP 7: PHOENIX LIVEVIEW - TASK SHOW (View Single Task)
# =============================================================================

defmodule TodoAppWeb.TaskLive.Show do
  @moduledoc "Displays a single task with details"

  use TodoAppWeb, :live_view

  alias TodoApp.Todos

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    task = Todos.get_task!(id, load: [:categories, :tags])

    {:ok,
     socket
     |> assign(:page_title, task.title)
     |> assign(:task, task)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-3xl mx-auto px-4 py-8">
      <div class="bg-white rounded-lg shadow-md p-6">
        <div class="flex justify-between items-start mb-4">
          <h1 class="text-3xl font-bold text-gray-900"><%= @task.title %></h1>
          <div class="flex gap-2">
            <.link
              href={~p"/tasks/#{@task.id}/edit"}
              class="bg-green-600 text-white px-4 py-2 rounded-md hover:bg-green-700"
            >
              Edit
            </.link>
          </div>
        </div>

        <div class="space-y-4">
          <div>
            <h3 class="text-sm font-medium text-gray-500">Description</h3>
            <p class="mt-1 text-gray-900"><%= @task.description || "No description" %></p>
          </div>

          <div class="grid grid-cols-2 gap-4">
            <div>
              <h3 class="text-sm font-medium text-gray-500">Priority</h3>
              <p class="mt-1"><%= String.capitalize(to_string(@task.priority)) %></p>
            </div>

            <div>
              <h3 class="text-sm font-medium text-gray-500">Status</h3>
              <p class="mt-1"><%= String.capitalize(to_string(@task.status)) %></p>
            </div>

            <div>
              <h3 class="text-sm font-medium text-gray-500">Due Date</h3>
              <p class="mt-1"><%= if @task.due_date, do: @task.due_date, else: "Not set" %></p>
            </div>

            <div>
              <h3 class="text-sm font-medium text-gray-500">Completed</h3>
              <p class="mt-1"><%= if @task.completed, do: "Yes ✅", else: "No" %></p>
            </div>
          </div>

          <div :if={length(@task.categories) > 0}>
            <h3 class="text-sm font-medium text-gray-500">Categories</h3>
            <div class="mt-2 flex flex-wrap gap-2">
              <span
                :for={category <- @task.categories}
                class="px-3 py-1 text-sm rounded-full bg-blue-100 text-blue-800"
              >
                <%= category.name %>
              </span>
            </div>
          </div>

          <div :if={length(@task.tags) > 0}>
            <h3 class="text-sm font-medium text-gray-500">Tags</h3>
            <div class="mt-2 flex flex-wrap gap-2">
              <span
                :for={tag <- @task.tags}
                class="px-3 py-1 text-sm rounded-full bg-purple-100 text-purple-800"
              >
                #<%= tag.name %>
              </span>
            </div>
          </div>
        </div>
      </div>

      <div class="mt-6">
        <.link href={~p"/tasks"} class="text-gray-600 hover:text-gray-900">
          ← Back to Tasks
        </.link>
      </div>
    </div>
    """
  end
end

# =============================================================================
# STEP 8: ROUTES (lib/todo_app_web/router.ex)
# =============================================================================

defmodule TodoAppWeb.Router do
  use TodoAppWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {TodoAppWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/", TodoAppWeb do
    pipe_through :browser

    # Task routes
    live "/tasks", TaskLive.Index, :index
    live "/tasks/new", TaskLive.Form, :new
    live "/tasks/:id", TaskLive.Show, :show
    live "/tasks/:id/edit", TaskLive.Form, :edit
  end
end

# =============================================================================
# STEP 9: RUNNING THE APP
# =============================================================================

# 1. Get dependencies:
#    $ mix deps.get

# 2. Create and migrate database:
#    $ mix ecto.setup

# 3. Start the server:
#    $ mix phx.server

# 4. Visit: http://localhost:4000/tasks

# =============================================================================
# STEP 10: TESTING
# =============================================================================

# test/todo_app_web/live/task_live_test.exs

defmodule TodoAppWeb.TaskLiveTest do
  use TodoAppWeb.ConnCase

  import Phoenix.LiveViewTest
  import TodoApp.TodosFixtures

  alias TodoApp.Todos

  describe "Index" do
    test "lists all tasks", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/tasks")

      assert html =~ "Tasks"
      assert html =~ "New Task"
    end
  end

  describe "Create Task" do
    test "renders form", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/tasks/new")

      assert html =~ "New Task"
      assert html =~ "Task Title"
    end

    test "creates task and redirects", %{conn: conn} do
      {:ok, live, _html} = live(conn, ~p"/tasks/new")

      assert form(live, "#task-form", task: %{
        title: "Test Task",
        description: "Test description",
        priority: "high"
      }) |> render_submit()
    end

    test "creates tag on-the-fly via creatable combobox", %{conn: conn} do
      {:ok, live, _html} = live(conn, ~p"/tasks/new")

      # Simulate creating a new tag
      {:noreply, _updated_socket} =
        AshFormBuilder.FormComponent.handle_event(
          "create_combobox_item",
          %{
            "field" => "tags",
            "resource" => "Elixir.TodoApp.Todos.Tag",
            "action" => "create",
            "creatable_value" => "Create \"urgent\""
          },
          live.socket
        )

      # Verify tag was created
      assert %TodoApp.Todos.Tag{name: "urgent"} =
               Ash.read_one!(TodoApp.Todos.Tag, name: "urgent")
    end
  end

  describe "Edit Task" do
    setup [:create_task]

    test "renders edit form", %{conn: conn, task: task} do
      {:ok, _index_live, html} = live(conn, ~p"/tasks/#{task.id}/edit")

      assert html =~ "Edit Task"
      assert html =~ task.title
    end

    test "updates task and redirects", %{conn: conn, task: task} do
      {:ok, live, _html} = live(conn, ~p"/tasks/#{task.id}/edit")

      assert form(live, "#task-form", task: %{
        title: "Updated Task"
      }) |> render_submit()
    end

    defp create_task(_) do
      task = task_fixture()
      %{task: task}
    end
  end
end

# =============================================================================
# END OF TODO APP GUIDE
# =============================================================================
