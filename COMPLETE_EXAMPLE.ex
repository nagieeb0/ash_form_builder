# =============================================================================
# AshFormBuilder - Complete Feature Demonstration
# =============================================================================
#
# This example demonstrates ALL features of AshFormBuilder:
# - Auto-inferred fields from Ash actions
# - File uploads with Phoenix LiveView integration
# - Many-to-many relationships with searchable combobox
# - Creatable combobox (create related records on-the-fly)
# - Dynamic nested forms for has_many relationships
# - Domain code interfaces
# - Create and Update forms
# - Full LiveView integration
#
# Scenario: Building a Project Management System
# =============================================================================

# =============================================================================
# 1. DOMAIN CONFIGURATION
# =============================================================================

defmodule MyApp.ProjectManagement do
  @moduledoc """
  Project Management Domain with Code Interfaces.
  
  Code Interfaces generate helper functions like:
  - MyApp.ProjectManagement.form_to_create_project/2
  - MyApp.ProjectManagement.form_to_update_project/2
  """
  use Ash.Domain

  resources do
    # Main resource
    resource MyApp.ProjectManagement.Project do
      define :list_projects, action: :read
      define :get_project, action: :read, get_by: [:id]
      
      # Form code interfaces - generates Form helper modules
      define :form_to_create_project, action: :create
      define :form_to_update_project, action: :update
    end
    
    # Related resources
    resource MyApp.ProjectManagement.TeamMember do
      define :list_team_members, action: :read
      define :search_team_members, action: :read
      define :form_to_create_team_member, action: :create
    end
    
    resource MyApp.ProjectManagement.Tag do
      define :list_tags, action: :read
      define :search_tags, action: :read
    end
    
    resource MyApp.ProjectManagement.Task do
      define :list_tasks, action: :read
      define :form_to_create_task, action: :create
    end
    
    # Join resources (auto-managed, no forms needed)
    resource MyApp.ProjectManagement.ProjectMember do
      define :read_project_members, action: :read
    end
    
    resource MyApp.ProjectManagement.ProjectTag do
      define :read_project_tags, action: :read
    end
  end
end

# =============================================================================
# 2. MAIN RESOURCE WITH ALL FIELD TYPES
# =============================================================================

defmodule MyApp.ProjectManagement.Project do
  @moduledoc """
  Project resource demonstrating ALL AshFormBuilder features:
  
  Field Types:
  - :string → :text_input (auto-inferred)
  - :text → :textarea (auto-inferred)
  - :boolean → :checkbox (auto-inferred)
  - :date → :date picker (auto-inferred)
  - :enum → :select dropdown (auto-inferred)
  - many_to_many → :multiselect_combobox (auto-inferred)
  - has_many → :nested_form (auto-inferred)
  - :file → :file_upload (auto-inferred)
  """

  use Ash.Resource,
    domain: MyApp.ProjectManagement,
    data_layer: Ash.DataLayer.Ets,
    extensions: [AshFormBuilder]

  # ───────────────────────────────────────────────────────────────────────────
  # Attributes
  # ───────────────────────────────────────────────────────────────────────────

  attributes do
    uuid_primary_key :id

    # String fields - auto-inferred as :text_input
    attribute :name, :string do
      allow_nil? false
      description "Project name"
    end

    attribute :description, :text do
      description "Detailed project description"
    end

    attribute :client_name, :string do
      description "Client or stakeholder name"
    end

    # Date fields - auto-inferred as :date picker
    attribute :start_date, :date do
      allow_nil? false
    end

    attribute :deadline, :date do
      allow_nil? false
    end

    # Boolean field - auto-inferred as :checkbox
    attribute :active, :boolean do
      default true
      description "Is the project currently active?"
    end

    # Enum field - auto-inferred as :select dropdown
    attribute :status, :atom do
      constraints one_of: [:planning, :active, :on_hold, :completed, :cancelled]
      default :planning
    end

    attribute :priority, :atom do
      constraints one_of: [:low, :medium, :high, :critical]
      default :medium
    end

    # Budget as decimal
    attribute :budget, :decimal do
      allow_nil? true
    end

    # File upload fields - auto-inferred as :file_upload
    attribute :proposal_path, :string do
      description "Path to uploaded project proposal document"
    end

    attribute :contract_path, :string do
      description "Path to uploaded contract document"
    end

    # Timestamps
    timestamps()
  end

  # ───────────────────────────────────────────────────────────────────────────
  # Relationships
  # ───────────────────────────────────────────────────────────────────────────

  relationships do
    # Many-to-many: Team members assigned to project
    # Auto-inferred as :multiselect_combobox with search
    many_to_many :team_members, MyApp.ProjectManagement.TeamMember do
      through MyApp.ProjectManagement.ProjectMember
      source_attribute_on_join_resource :project_id
      destination_attribute_on_join_resource :team_member_id
    end

    # Many-to-many: Tags for categorization
    # Auto-inferred as :multiselect_combobox with CREATABLE support
    many_to_many :tags, MyApp.ProjectManagement.Tag do
      through MyApp.ProjectManagement.ProjectTag
      source_attribute_on_join_resource :project_id
      destination_attribute_on_join_resource :tag_id
    end

    # Has-many: Tasks within project
    # Auto-inferred as :nested_form with add/remove buttons
    has_many :tasks, MyApp.ProjectManagement.Task do
      destination_attribute_on_join_resource :project_id
    end
  end

  # ───────────────────────────────────────────────────────────────────────────
  # Actions
  # ───────────────────────────────────────────────────────────────────────────

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [
        :name,
        :description,
        :client_name,
        :start_date,
        :deadline,
        :active,
        :status,
        :priority,
        :budget
      ]

      # File upload arguments
      argument :proposal, :string, allow_nil?: true
      argument :contract, :string, allow_nil?: true

      # Manage relationships
      manage_relationship :team_members, :team_members, type: :append_and_remove
      manage_relationship :tags, :tags, type: :append_and_remove
      manage_relationship :tasks, :tasks, type: :create

      # Store file paths from arguments
      change fn changeset, _ ->
        changeset
        |> store_file_argument(:proposal, :proposal_path)
        |> store_file_argument(:contract, :contract_path)
      end
    end

    update :update do
      accept [
        :name,
        :description,
        :client_name,
        :start_date,
        :deadline,
        :active,
        :status,
        :priority,
        :budget
      ]

      # File upload arguments
      argument :proposal, :string, allow_nil?: true
      argument :contract, :string, allow_nil?: true

      manage_relationship :team_members, :team_members, type: :append_and_remove
      manage_relationship :tags, :tags, type: :append_and_remove
      manage_relationship :tasks, :tasks, type: :create

      change fn changeset, _ ->
        changeset
        |> store_file_argument(:proposal, :proposal_path)
        |> store_file_argument(:contract, :contract_path)
      end
    end
  end

  # ───────────────────────────────────────────────────────────────────────────
  # CREATE FORM Configuration
  # ───────────────────────────────────────────────────────────────────────────

  form do
    action :create
    submit_label "Create Project"
    wrapper_class "space-y-6"

    # ── Basic Fields (override auto-inferred defaults) ─────────────────────

    field :name do
      label "Project Name"
      placeholder "e.g., Website Redesign"
      required true
      hint "Choose a descriptive name for your project"
    end

    field :description do
      label "Description"
      placeholder "Describe the project goals, scope, and deliverables..."
      required true
      # Override auto-inferred :textarea with custom rows
      opts [rows: 5]
    end

    field :client_name do
      label "Client / Stakeholder"
      placeholder "Company or person name"
    end

    # ── Date Fields ────────────────────────────────────────────────────────

    field :start_date do
      label "Start Date"
      required true
      hint "When will work begin?"
    end

    field :deadline do
      label "Deadline"
      required true
      hint "Final delivery date"
    end

    # ── Select Fields (Enum) ──────────────────────────────────────────────

    field :status do
      label "Project Status"
      required true
      # Options auto-inferred from enum constraints
    end

    field :priority do
      label "Priority Level"
      required true
    end

    # ── Boolean Field ──────────────────────────────────────────────────────

    field :active do
      label "Active Project"
      hint "Uncheck if project is on hold or cancelled"
    end

    # ── Number Field ───────────────────────────────────────────────────────

    field :budget do
      label "Budget"
      placeholder "0.00"
      hint "Total project budget in USD"
      opts [step: "0.01", min: "0"]
    end

    # ── File Upload Fields ─────────────────────────────────────────────────

    field :proposal do
      type :file_upload
      label "Project Proposal"
      hint "Upload PDF or Word document (max 10 MB)"

      opts upload: [
        cloud: MyApp.ProjectManagement.Cloud,
        max_entries: 1,
        max_file_size: 10_000_000,
        accept: ~w(.pdf .doc .docx)
      ]
    end

    field :contract do
      type :file_upload
      label "Signed Contract"
      hint "Upload signed contract (max 10 MB)"

      opts upload: [
        cloud: MyApp.ProjectManagement.Cloud,
        max_entries: 1,
        max_file_size: 10_000_000,
        accept: ~w(.pdf .jpg .jpeg .png)
      ]
    end

    # ── Many-to-Many: Searchable Combobox (NON-CREATABLE) ─────────────────

    field :team_members do
      type :multiselect_combobox
      label "Team Members"
      placeholder "Search and select team members..."
      hint "Who will work on this project?"

      opts [
        search_event: "search_team_members",
        debounce: 300,
        label_key: :name,
        value_key: :id,
        preload_options: []  # Load via search
      ]
    end

    # ── Many-to-Many: Creatable Combobox ⭐ ────────────────────────────────

    field :tags do
      type :multiselect_combobox
      label "Tags"
      placeholder "Search or create tags..."
      hint "Categorize your project"

      opts [
        # Enable creating new tags on-the-fly
        creatable: true,
        create_action: :create,
        create_label: "Create \"\"",

        search_event: "search_tags",
        debounce: 300,
        label_key: :name,
        value_key: :id
      ]
    end

    # ── Nested Forms: Has-Many Relationship ───────────────────────────────

    nested :tasks do
      label "Initial Tasks"
      cardinality :many
      add_label "Add Task"
      remove_label "Remove"
      create_action :create
      update_action :update
      class "nested-tasks-fieldset"

      # Nested form fields
      field :title do
        label "Task Title"
        required true
        placeholder "e.g., Design mockups"
      end

      field :description do
        label "Description"
        type :textarea
        placeholder "Task details..."
      end

      field :priority do
        label "Priority"
        type :select
        options [
          {"Low", :low},
          {"Medium", :medium},
          {"High", :high}
        ]
      end

      field :due_date do
        label "Due Date"
        type :date
      end
    end
  end

  # ───────────────────────────────────────────────────────────────────────────
  # UPDATE FORM Configuration (Separate Block)
  # ───────────────────────────────────────────────────────────────────────────

  form do
    action :update
    submit_label "Save Changes"
    wrapper_class "space-y-6"

    # Can have different labels/hints for update forms
    field :name do
      label "Project Name"
      required true
      hint "Changing the name will notify all team members"
    end

    field :description do
      label "Description"
      opts [rows: 5]
    end

    field :client_name do
      label "Client / Stakeholder"
    end

    field :start_date do
      label "Start Date"
      required true
    end

    field :deadline do
      label "Deadline"
      required true
    end

    field :status do
      label "Project Status"
      required true
    end

    field :priority do
      label "Priority Level"
      required true
    end

    field :active do
      label "Active Project"
    end

    field :budget do
      label "Budget"
      opts [step: "0.01", min: "0"]
    end

    # File uploads - same config as create form
    field :proposal do
      type :file_upload
      label "Project Proposal"
      hint "Upload new proposal to replace existing one (max 10 MB)"

      opts upload: [
        cloud: MyApp.ProjectManagement.Cloud,
        max_entries: 1,
        max_file_size: 10_000_000,
        accept: ~w(.pdf .doc .docx)
      ]
    end

    field :contract do
      type :file_upload
      label "Signed Contract"
      hint "Upload new contract to replace existing one (max 10 MB)"

      opts upload: [
        cloud: MyApp.ProjectManagement.Cloud,
        max_entries: 1,
        max_file_size: 10_000_000,
        accept: ~w(.pdf .jpg .jpeg .png)
      ]
    end

    # Relationships - same as create form
    field :team_members do
      type :multiselect_combobox
      label "Team Members"
      placeholder "Search and select team members..."

      opts [
        search_event: "search_team_members",
        debounce: 300,
        label_key: :name,
        value_key: :id
      ]
    end

    field :tags do
      type :multiselect_combobox
      label "Tags"
      placeholder "Search or create tags..."

      opts [
        creatable: true,
        create_action: :create,
        create_label: "Create \"\"",
        search_event: "search_tags",
        debounce: 300,
        label_key: :name,
        value_key: :id
      ]
    end

    nested :tasks do
      label "Tasks"
      cardinality :many
      add_label "Add Task"
      remove_label "Remove"
      create_action :create
      update_action :update

      field :title do
        label "Task Title"
        required true
      end

      field :description do
        label "Description"
        type :textarea
      end

      field :priority do
        label "Priority"
        type :select
        options [
          {"Low", :low},
          {"Medium", :medium},
          {"High", :high}
        ]
      end

      field :due_date do
        label "Due Date"
        type :date
      end
    end
  end

  # ───────────────────────────────────────────────────────────────────────────
  # Validations & Policies
  # ───────────────────────────────────────────────────────────────────────────

  validations do
    validate present([:name, :start_date, :deadline])
    validate string_length(:name, min: 3, max: 100)
    validate before_or_equal(:start_date, :deadline)
  end

  policies do
    policy action_type(:create) do
      authorize_if actor_present()
    end

    policy action_type(:update) do
      authorize_if actor_present()
    end

    policy action_type(:read) do
      authorize_if actor_present()
    end
  end

  # ───────────────────────────────────────────────────────────────────────────
  # Helpers
  # ───────────────────────────────────────────────────────────────────────────

  defp store_file_argument(changeset, argument_name, attribute_name) do
    case Ash.Changeset.get_argument(changeset, argument_name) do
      nil -> changeset
      path -> Ash.Changeset.change_attribute(changeset, attribute_name, path)
    end
  end
end

# =============================================================================
# 3. SUPPORTING RESOURCES
# =============================================================================

defmodule MyApp.ProjectManagement.TeamMember do
  @moduledoc "Team member resource"

  use Ash.Resource,
    domain: MyApp.ProjectManagement,
    data_layer: Ash.DataLayer.Ets

  attributes do
    uuid_primary_key :id
    attribute :name, :string, allow_nil?: false
    attribute :email, :string, allow_nil?: false
    attribute :role, :string
  end

  actions do
    defaults [:read, :create]

    read :search do
      argument :query, :string, allow_nil?: false
      filter expr(ilike(name, ^"%#{query}%") or ilike(email, ^"%#{query}%"))
    end
  end
end

defmodule MyApp.ProjectManagement.Tag do
  @moduledoc "Tag resource (creatable on-the-fly)"

  use Ash.Resource,
    domain: MyApp.ProjectManagement,
    data_layer: Ash.DataLayer.Ets

  attributes do
    uuid_primary_key :id
    attribute :name, :string, allow_nil?: false
    attribute :color, :string, default: "blue"
  end

  actions do
    defaults [:read, :create]

    read :search do
      argument :query, :string, allow_nil?: false
      filter expr(ilike(name, ^"%#{query}%"))
    end
  end
end

defmodule MyApp.ProjectManagement.Task do
  @moduledoc "Task resource for nested forms"

  use Ash.Resource,
    domain: MyApp.ProjectManagement,
    data_layer: Ash.DataLayer.Ets

  attributes do
    uuid_primary_key :id
    attribute :title, :string, allow_nil?: false
    attribute :description, :text
    attribute :priority, :atom, constraints: [one_of: [:low, :medium, :high]]
    attribute :due_date, :date
    attribute :completed, :boolean, default: false
  end

  relationships do
    belongs_to :project, MyApp.ProjectManagement.Project
  end

  actions do
    defaults [:read, :create, :update, :destroy]
  end
end

# Join resources
defmodule MyApp.ProjectManagement.ProjectMember do
  use Ash.Resource,
    domain: MyApp.ProjectManagement

  attributes do
    uuid_primary_key :id
    attribute :project_id, :uuid, allow_nil?: false
    attribute :team_member_id, :uuid, allow_nil?: false
  end

  relationships do
    belongs_to :project, MyApp.ProjectManagement.Project
    belongs_to :team_member, MyApp.ProjectManagement.TeamMember
  end
end

defmodule MyApp.ProjectManagement.ProjectTag do
  use Ash.Resource,
    domain: MyApp.ProjectManagement

  attributes do
    uuid_primary_key :id
    attribute :project_id, :uuid, allow_nil?: false
    attribute :tag_id, :uuid, allow_nil?: false
  end

  relationships do
    belongs_to :project, MyApp.ProjectManagement.Project
    belongs_to :tag, MyApp.ProjectManagement.Tag
  end
end

# =============================================================================
# 4. CLOUD MODULE FOR FILE STORAGE
# =============================================================================

defmodule MyApp.ProjectManagement.Cloud do
  @moduledoc """
  Buckets.Cloud implementation for file storage.
  """

  use Buckets.Cloud, otp_app: :my_app

  # Configuration in config/config.exs:
  #
  # config :my_app, MyApp.ProjectManagement.Cloud,
  #   adapter: Buckets.Adapters.Volume,
  #   bucket: "priv/uploads",
  #   base_url: "http://localhost:4000/uploads"
end

# =============================================================================
# 5. LIVEVIEW IMPLEMENTATION
# =============================================================================

defmodule MyAppWeb.ProjectLive.Form do
  @moduledoc """
  LiveView demonstrating complete AshFormBuilder integration.
  """

  use MyAppWeb, :live_view

  alias MyApp.ProjectManagement

  # ───────────────────────────────────────────────────────────────────────────
  # Mount - Create Form
  # ───────────────────────────────────────────────────────────────────────────

  def mount(_params, _session, socket) do
    # Domain code interface generates this helper
    form = ProjectManagement.form_to_create_project(
      actor: socket.assigns.current_user,
      domain: ProjectManagement
    )

    {:ok,
     socket
     |> assign(:page_title, "New Project")
     |> assign(:form, form)
     |> assign(:mode, :create)}
  end

  # ───────────────────────────────────────────────────────────────────────────
  # Mount - Update Form (with ID param)
  # ───────────────────────────────────────────────────────────────────────────

  def mount(%{"id" => id}, _session, socket) do
    project = ProjectManagement.get_project!(id,
      actor: socket.assigns.current_user,
      load: [:team_members, :tags, :tasks]
    )

    # for_update/2 auto-preloads many_to_many relationships
    form = ProjectManagement.form_to_update_project(project,
      actor: socket.assigns.current_user,
      domain: ProjectManagement
    )

    {:ok,
     socket
     |> assign(:page_title, "Edit Project")
     |> assign(:form, form)
     |> assign(:mode, :edit)
     |> assign(:project, project)}
  end

  # ───────────────────────────────────────────────────────────────────────────
  # Render
  # ───────────────────────────────────────────────────────────────────────────

  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto px-4 py-8">
      <h1 class="text-3xl font-bold mb-6">{@page_title}</h1>

      <div class="card bg-base-100 shadow-xl">
        <div class="card-body">
          <.live_component
            module={AshFormBuilder.FormComponent}
            id="project-form"
            resource={MyApp.ProjectManagement.Project}
            form={@form}
          />
        </div>
      </div>
    </div>
    """
  end

  # ───────────────────────────────────────────────────────────────────────────
  # Search Handlers for Combobox
  # ───────────────────────────────────────────────────────────────────────────

  def handle_event("search_team_members", %{"query" => query}, socket) do
    team_members =
      ProjectManagement.TeamMember
      |> Ash.Query.filter(ilike(name, ^"%#{query}%") or ilike(email, ^"%#{query}%"))
      |> ProjectManagement.read!(actor: socket.assigns.current_user)

    options = Enum.map(team_members, &{&1.name, &1.id})

    {:noreply, push_event(socket, "update_combobox_options", %{
      field: "team_members",
      options: options
    })}
  end

  def handle_event("search_tags", %{"query" => query}, socket) do
    tags =
      ProjectManagement.Tag
      |> Ash.Query.filter(ilike(name, ^"%#{query}%"))
      |> ProjectManagement.read!(actor: socket.assigns.current_user)

    options = Enum.map(tags, &{&1.name, &1.id})

    {:noreply, push_event(socket, "update_combobox_options", %{
      field: "tags",
      options: options
    })}
  end

  # ───────────────────────────────────────────────────────────────────────────
  # Form Submission Handler
  # ───────────────────────────────────────────────────────────────────────────

  def handle_info({:form_submitted, MyApp.ProjectManagement.Project, project}, socket) do
    message = case socket.assigns.mode do
      :create -> "Project created successfully!"
      :update -> "Project updated successfully!"
    end

    {:noreply,
     socket
     |> put_flash(:info, message)
     |> push_navigate(to: ~p"/projects/#{project.id}")}
  end
end

# =============================================================================
# 6. TESTING EXAMPLE
# =============================================================================

defmodule MyAppWeb.ProjectLive.FormTest do
  @moduledoc """
  Comprehensive test examples for all AshFormBuilder features.
  """

  use MyAppWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  setup do
    # Configure test theme
    Application.put_env(:ash_form_builder, :theme, AshFormBuilder.Themes.Default)
    {:ok, conn: build_conn()}
  end

  # ───────────────────────────────────────────────────────────────────────────
  # Basic Form Tests
  # ───────────────────────────────────────────────────────────────────────────

  test "CREATE form renders all field types", %{conn: conn} do
    {:ok, view, html} = live_isolated(conn, MyAppWeb.ProjectLive.Form)

    # Text inputs
    assert html =~ "Project Name"
    assert html =~ "Description"
    assert html =~ "Client / Stakeholder"

    # Date pickers
    assert html =~ "Start Date"
    assert html =~ "Deadline"

    # Select dropdowns
    assert html =~ "Project Status"
    assert html =~ "Priority Level"

    # Checkbox
    assert html =~ "Active Project"

    # Number input
    assert html =~ "Budget"
  end

  test "form validation shows errors on required fields", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, MyAppWeb.ProjectLive.Form)

    html =
      view
      |> form("#project-form", %{"name" => "", "start_date" => ""})
      |> render_submit()

    assert html =~ "can't be blank" or html =~ "required"
  end

  # ───────────────────────────────────────────────────────────────────────────
  # File Upload Tests
  # ───────────────────────────────────────────────────────────────────────────

  test "file upload field renders correctly", %{conn: conn} do
    {:ok, view, html} = live_isolated(conn, MyAppWeb.ProjectLive.Form)

    # Check file input is rendered
    assert html =~ "Project Proposal"
    assert html =~ "data-phx-upload-ref" or html =~ "phx-drop-target"
  end

  test "uploading proposal document", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, MyAppWeb.ProjectLive.Form)

    # Select file for upload
    upload =
      file_input(view, "#project-form", :proposal, [
        %{
          name: "proposal.pdf",
          content: :binary.copy(<<0x25, 0x50, 0x44, 0x46>>, 100), # PDF header
          type: "application/pdf"
        }
      ])

    # Simulate upload progress
    render_upload(upload, 100)

    # Submit form with other required fields
    view
    |> form("#project-form", %{
      "name" => "Test Project",
      "start_date" => "2024-01-01",
      "deadline" => "2024-12-31"
    })
    |> render_submit()

    # Assert success
    assert render(view) =~ "Project created successfully!"
  end

  test "file too large shows error", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, MyAppWeb.ProjectLive.Form)

    # Try to upload 15 MB file (max is 10 MB)
    big_file = :binary.copy(<<0>>, 15_000_000)

    upload =
      file_input(view, "#project-form", :proposal, [
        %{name: "huge.pdf", content: big_file, type: "application/pdf"}
      ])

    html = render_upload(upload, 100)

    # Assert error message
    assert html =~ "too large" or html =~ "File is too large"
  end

  # ───────────────────────────────────────────────────────────────────────────
  # Combobox Tests (would need proper setup)
  # ───────────────────────────────────────────────────────────────────────────

  # test "team members combobox search", %{conn: conn} do
  #   {:ok, view, _html} = live_isolated(conn, MyAppWeb.ProjectLive.Form)
  #
  #   # Trigger search event
  #   {:noreply, _socket} =
  #     AshFormBuilder.FormComponent.handle_event(
  #       "search_team_members",
  #       %{"query" => "john"},
  #       view.socket
  #     )
  #
  #   # Verify search results pushed via event
  #   assert_pushed_event(view, "update_combobox_options", %{
  #     field: "team_members",
  #     options: options
  #   }) when length(options) > 0
  # end

  # ───────────────────────────────────────────────────────────────────────────
  # Nested Form Tests
  # ───────────────────────────────────────────────────────────────────────────

  test "add nested task form", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, MyAppWeb.ProjectLive.Form)

    # Click add task button
    view |> element(".btn-add-nested") |> render_click()

    # Assert new task form is rendered
    html = render(view)
    assert html =~ "Task Title"
    assert html =~ "Remove"
  end

  test "remove nested task form", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, MyAppWeb.ProjectLive.Form)

    # Add a task
    view |> element(".btn-add-nested") |> render_click()

    # Remove the task
    view |> element(".btn-remove-nested") |> render_click()

    # Assert task form is removed
    refute render(view) =~ "Task Title"
  end

  # ───────────────────────────────────────────────────────────────────────────
  # Integration Test: Full Create Flow
  # ───────────────────────────────────────────────────────────────────────────

  @tag :integration
  test "complete project creation with all features", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, MyAppWeb.ProjectLive.Form)

    # Upload proposal
    proposal_upload =
      file_input(view, "#project-form", :proposal, [
        %{
          name: "proposal.pdf",
          content: :binary.copy(<<0x25, 0x50, 0x44, 0x46>>, 100),
          type: "application/pdf"
        }
      ])

    render_upload(proposal_upload, 100)

    # Fill in form
    form_params = %{
      "name" => "Website Redesign",
      "description" => "Complete website overhaul",
      "client_name" => "Acme Corp",
      "start_date" => "2024-01-01",
      "deadline" => "2024-06-30",
      "status" => "planning",
      "priority" => "high",
      "active" => "true",
      "budget" => "50000.00"
    }

    # Add nested task
    view |> element(".btn-add-nested") |> render_click()

    # Fill nested task
    view
    |> form("#project-form", Map.put(form_params, "tasks", %{
      "0" => %{
        "title" => "Design mockups",
        "description" => "Create initial designs",
        "priority" => "high",
        "due_date" => "2024-02-01"
      }
    }))
    |> render_submit()

    # Assert success
    assert render(view) =~ "Project created successfully!"
  end
end

# =============================================================================
# 7. ROUTER CONFIGURATION
# =============================================================================

defmodule MyAppWeb.Router do
  use Phoenix.Router

  import Phoenix.LiveView.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {MyAppWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", MyAppWeb do
    pipe_through :browser

    # Project forms
    live "/projects/new", ProjectLive.Form, :new
    live "/projects/:id/edit", ProjectLive.Form, :edit
  end
end

# =============================================================================
# 8. CONFIGURATION
# =============================================================================

# config/config.exs
#
# import Config
#
# # AshFormBuilder Theme
# config :ash_form_builder, :theme, AshFormBuilder.Themes.Default
# # or
# # config :ash_form_builder, :theme, AshFormBuilder.Theme.MishkaTheme
#
# # Buckets.Cloud Configuration
# config :my_app, MyApp.ProjectManagement.Cloud,
#   adapter: Buckets.Adapters.Volume,
#   bucket: "priv/uploads/projects",
#   base_url: "http://localhost:4000/uploads"
#
# # Ash Domains
# config :ash_form_builder, ash_domains: [MyApp.ProjectManagement]

# =============================================================================
# END OF COMPLETE EXAMPLE
# =============================================================================
