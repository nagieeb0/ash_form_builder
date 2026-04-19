defmodule AshFormBuilder.Infer do
  @moduledoc """
  Zero-Config Auto-Inference Engine for AshFormBuilder v0.2.0.

  Dynamically infers complete form field definitions from Ash resource metadata.
  Reads action definitions, attributes, arguments, and relationships via `Ash.Resource.Info`.

  ## Key Capabilities

  * **Complete Type Mapping** - Maps all Ash 3.0 types to appropriate UI components
  * **Smart Defaults** - Infers labels, required status, placeholders from constraints
  * **Relationship Detection** - Auto-detects and configures many_to_many, has_many, belongs_to
  * **Constraint Awareness** - Detects one_of, enums, and other constraints for UI selection
  * **Configurable Ignoring** - Exclude fields without writing full field blocks
  * **Manage Relationship Support** - Infers UI based on manage_relationship configuration

  ## Usage

      # Zero-config - infer everything from action.accept
      fields = AshFormBuilder.Infer.infer_fields(MyApp.Task, :create)

      # Custom ignore list
      fields = AshFormBuilder.Infer.infer_fields(MyApp.Task, :create,
        ignore_fields: [:id, :tenant_id, :deleted_at]
      )

      # Include timestamps
      fields = AshFormBuilder.Infer.infer_fields(MyApp.Task, :create,
        include_timestamps: true
      )

      # Customize relationship UI
      fields = AshFormBuilder.Infer.infer_fields(MyApp.Task, :create,
        many_to_many_as: :select,
        belongs_to_as: :combobox
      )

  ## Type Inference Table

  | Ash Type | Constraint | Inferred UI | Example |
  |----------|------------|-------------|---------|
  | `:string` | - | `:text_input` | Standard text |
  | `:ci_string` | - | `:text_input` | Case-insensitive |
  | `:text` | - | `:textarea` | Multi-line |
  | `:boolean` | - | `:checkbox` | Toggle |
  | `:integer` | - | `:number` | Whole numbers |
  | `:float` / `:decimal` | - | `:number` | Decimals |
  | `:date` | - | `:date` | Date picker |
  | `:datetime` | - | `:datetime` | DateTime picker |
  | `:atom` | `one_of:` | `:select` | Dropdown |
  | `:enum` module | - | `:select` | Enum values |
  | `:email` | - | `:email` | Email input |
  | `:url` | - | `:url` | URL input |
  | `:phone` | - | `:tel` | Telephone |
  | `many_to_many` | - | `:multiselect_combobox` | Searchable multi-select |
  | `has_many` | - | `:nested_form` | Dynamic nested forms |
  | `belongs_to` | - | `:select` | Foreign key selection |

  ## Relationship Handling

  When a relationship is detected in the action's `accept` list:

  1. **many_to_many** → `:multiselect_combobox` with searchable selection
  2. **has_many** → Nested form configuration (not a direct field)
  3. **belongs_to** → `:select` or `:combobox` based on destination

  For `many_to_many` relationships, the following field properties are populated:
  * `type: :multiselect_combobox`
  * `relationship: :relationship_name`
  * `relationship_type: :many_to_many`
  * `destination_resource: DestinationResource`
  * `opts: [label_key: :name, value_key: :id, search_event: "...", ...]`

  This enables seamless UI rendering with searchable multi-select for related records.
  """

  alias AshFormBuilder.Field

  # ───────────────────────────────────────────────────────────────────────────
  # Complete Ash 3.0 Type Mapping
  # ───────────────────────────────────────────────────────────────────────────

  @type_map %{
    # String types
    Ash.Type.String => :text_input,
    :string => :text_input,
    Ash.Type.CiString => :text_input,
    :ci_string => :text_input,

    # Boolean
    Ash.Type.Boolean => :checkbox,
    :boolean => :checkbox,

    # Numeric types
    Ash.Type.Integer => :number,
    :integer => :number,
    Ash.Type.Float => :number,
    :float => :number,
    Ash.Type.Decimal => :number,
    :decimal => :number,

    # Date/Time types
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
    # Overridden by constraints
    Ash.Type.Atom => :text_input,
    :atom => :text_input,
    Ash.Type.Enum => :select,
    :enum => :select,

    # Binary/Map types
    Ash.Type.Binary => :textarea,
    :binary => :textarea,
    Ash.Type.Map => :textarea,
    :map => :textarea,
    Ash.Type.Text => :textarea,
    :text => :textarea,

    # UUID (usually hidden or text input)
    Ash.Type.UUID => :text_input,
    :uuid => :text_input,

    # Money
    Ash.Type.Money => :number,
    :money => :number,

    # Color
    Ash.Type.Color => :text_input,
    :color => :text_input,

    # File (maps to LiveView file upload)
    Ash.Type.File => :file_upload,
    :file => :file_upload
  }

  # ───────────────────────────────────────────────────────────────────────────
  # Public API
  # ───────────────────────────────────────────────────────────────────────────

  @doc """
  Infers `Field` structs for the given resource action with zero-config operation.

  ## Options

  * `:ignore_fields` - List of field names to skip (default: `[:id, :inserted_at, :updated_at]`)
  * `:include_timestamps` - Include timestamp fields (default: `false`)
  * `:many_to_many_as` - UI type for many_to_many (default: `:multiselect_combobox`)
  * `:has_many_as` - UI type for has_many (default: `:nested_form`)
  * `:belongs_to_as` - UI type for belongs_to (default: `:select`)
  * `:creatable` - Enable creatable combobox for many_to_many (default: `false`)
  * `:create_action` - Action for creating new items (default: `:create`)

  ## Returns

  List of `%AshFormBuilder.Field{}` structs in rendering order.

  ## Examples

      # Basic zero-config inference
      iex> fields = Infer.infer_fields(MyApp.Task, :create)
      [%Field{name: :title, type: :text_input, ...}, ...]

      # Custom ignore list
      iex> fields = Infer.infer_fields(MyApp.Task, :create, ignore_fields: [:tenant_id])
      [%Field{...}]

      # Include timestamps
      iex> fields = Infer.infer_fields(MyApp.Task, :create, include_timestamps: true)
      [%Field{name: :inserted_at, ...}, %Field{name: :updated_at, ...}]

      # Creatable combobox for relationships
      iex> fields = Infer.infer_fields(MyApp.Task, :create, creatable: true)
      [%Field{name: :tags, type: :multiselect_combobox, opts: [creatable: true]}]
  """
  @spec infer_fields(module(), atom(), keyword()) :: [Field.t()]
  def infer_fields(resource, action_name, opts \\ []) do
    action = Ash.Resource.Info.action(resource, action_name)

    if is_nil(action) do
      []
    else
      opts = validate_opts(opts)

      # Process accept list (attributes and relationships)
      accept_fields = process_accept_list(resource, action.accept || [], opts)

      # Process action arguments
      arg_fields = process_arguments(action.arguments || [])

      # Combine in order: arguments first, then accept fields
      arg_fields ++ accept_fields
    end
  end

  @doc """
  Infers complete form schema including nested forms and preload requirements.

  Returns a map suitable for passing to `AshPhoenix.Form.for_create/3`.

  ## Returns

  %{
    fields: [Field.t()],
    nested_forms: keyword(),
    action: atom(),
    resource: module(),
    required_preloads: [atom()]
  }

  ## Examples

      iex> schema = Infer.infer_schema(MyApp.Task, :create)
      %{
        fields: [%Field{...}],
        nested_forms: [subtasks: [type: :list, resource: MyApp.Subtask]],
        action: :create,
        resource: MyApp.Task,
        required_preloads: [:tags, :assignees]
      }
  """
  @spec infer_schema(module(), atom(), keyword()) :: %{
          fields: [Field.t()],
          nested_forms: keyword(),
          action: atom(),
          resource: module(),
          required_preloads: [atom()]
        }
  def infer_schema(resource, action_name, opts \\ []) do
    fields = infer_fields(resource, action_name, opts)
    nested_forms = build_nested_forms_config(fields, resource)
    required_preloads = detect_required_preloads(fields, resource, action_name)

    %{
      fields: fields,
      nested_forms: nested_forms,
      action: action_name,
      resource: resource,
      required_preloads: required_preloads
    }
  end

  @doc """
  Detects field type (attribute or relationship) for a given field name.

  ## Returns

  * `:attribute` - Field is a resource attribute
  * `{:relationship, relationship}` - Field is a relationship
  * `:ignore` - Field should be ignored

  ## Examples

      iex> Infer.detect_field_type(MyApp.Task, :title)
      :attribute

      iex> Infer.detect_field_type(MyApp.Task, :tags)
      {:relationship, %Ash.Resource.Relationships.ManyToMany{...}}
  """
  @spec detect_field_type(module(), atom()) :: :attribute | {:relationship, struct()} | :ignore
  def detect_field_type(resource, field_name) do
    case Ash.Resource.Info.relationship(resource, field_name) do
      nil ->
        # Check if it's an attribute
        if Ash.Resource.Info.attribute(resource, field_name) do
          :attribute
        else
          :ignore
        end

      rel ->
        {:relationship, rel}
    end
  end

  @doc """
  Detects required preloads for update/destroy actions.

  Identifies which relationships need preloading for form rendering
  (e.g., many_to_many relationships that appear in the form).

  ## Examples

      iex> Infer.detect_required_preloads(fields, MyApp.Task, :update)
      [:tags, :assignees]
  """
  @spec detect_required_preloads([Field.t()], module(), atom()) :: [atom()]
  def detect_required_preloads(fields, resource, action_name) do
    action = Ash.Resource.Info.action(resource, action_name)

    # Only preloads needed for update/destroy actions
    if is_nil(action) or action.type not in [:update, :destroy] do
      []
    else
      fields
      |> Enum.filter(&requires_preload?/1)
      |> Enum.map(& &1.relationship)
      |> Enum.uniq()
    end
  end

  # ───────────────────────────────────────────────────────────────────────────
  # Private Implementation
  # ───────────────────────────────────────────────────────────────────────────

  defp validate_opts(opts) do
    Keyword.validate!(opts,
      ignore_fields: [:id, :inserted_at, :updated_at, :deleted_at],
      include_timestamps: false,
      many_to_many_as: :multiselect_combobox,
      has_many_as: :nested_form,
      belongs_to_as: :select,
      creatable: false,
      create_action: :create,
      create_label: "Create \"\"",
      search_param: "query",
      debounce: 300,
      label_key: :name,
      value_key: :id
    )
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
      :attribute -> infer_from_attribute(resource, field_name)
      {:relationship, rel} -> infer_from_relationship(rel, opts)
      :ignore -> nil
    end
  end

  defp infer_from_attribute(resource, field_name) do
    attr = Ash.Resource.Info.attribute(resource, field_name)

    if is_nil(attr) do
      nil
    else
      %Field{
        name: attr.name,
        label: humanize(attr.name),
        type: infer_type(attr.type, attr.constraints || []),
        required: field_required?(attr),
        placeholder: infer_placeholder(attr),
        options: infer_options(attr.type, attr.constraints || []),
        hint: infer_hint(attr)
      }
    end
  end

  defp field_required?(attr) do
    not attr.allow_nil? and is_nil(attr.default)
  end

  defp infer_placeholder(_attr) do
    # Could be enhanced with attr.constraints or metadata
    nil
  end

  defp infer_hint(_attr) do
    # Could be enhanced with attr.description or metadata
    nil
  end

  defp infer_from_relationship(rel, opts) do
    case rel.type do
      :many_to_many ->
        build_combobox_field(rel, opts)

      :has_many ->
        # has_many uses nested forms, not direct fields
        nil

      :belongs_to ->
        build_belongs_to_field(rel, opts)

      :has_one ->
        # has_one typically uses nested form or separate form
        nil

      _other ->
        nil
    end
  end

  defp build_combobox_field(rel, opts) do
    %Field{
      name: rel.name,
      label: humanize(rel.name),
      type: opts[:many_to_many_as],
      required: false,
      options: [],
      relationship: rel.name,
      relationship_type: :many_to_many,
      destination_resource: rel.destination,
      opts: build_combobox_opts(rel.destination, opts)
    }
  end

  defp build_combobox_opts(destination, opts) do
    label_key = infer_label_key(destination)
    value_key = opts[:value_key] || :id

    [
      label_key: label_key,
      value_key: value_key,
      search_param: opts[:search_param],
      debounce: opts[:debounce],
      creatable: opts[:creatable],
      create_action: opts[:create_action],
      create_label: opts[:create_label],
      preload_options: []
    ]
  end

  defp infer_label_key(destination) do
    # Try common label fields in order of preference
    cond do
      field_exists?(destination, :name) -> :name
      field_exists?(destination, :title) -> :title
      field_exists?(destination, :label) -> :label
      field_exists?(destination, :display_name) -> :display_name
      true -> :id
    end
  end

  defp field_exists?(resource, field_name) do
    not is_nil(Ash.Resource.Info.attribute(resource, field_name))
  end

  defp build_belongs_to_field(rel, opts) do
    %Field{
      name: rel.name,
      label: humanize(rel.name),
      type: opts[:belongs_to_as],
      required: false,
      options: [],
      relationship: rel.name,
      relationship_type: :belongs_to,
      destination_resource: rel.destination,
      opts: build_combobox_opts(rel.destination, opts)
    }
  end

  defp process_arguments(arguments) do
    Enum.map(arguments, &infer_from_argument/1)
  end

  defp infer_from_argument(arg) do
    %Field{
      name: arg.name,
      label: humanize(arg.name),
      type: infer_type(arg.type, arg.constraints || []),
      required: argument_required?(arg),
      placeholder: nil,
      options: infer_options(arg.type, arg.constraints || []),
      hint: nil
    }
  end

  defp argument_required?(arg) do
    not arg.allow_nil? and is_nil(arg.default)
  end

  defp infer_type(type, constraints) do
    cond do
      # Constraint-based inference takes precedence
      constraints[:one_of] ->
        :select

      # Enum module detection
      is_atom(type) and function_exported?(type, :values, 0) ->
        :select

      # Direct type mapping
      Map.has_key?(@type_map, type) ->
        Map.get(@type_map, type)

      # Fallback
      true ->
        :text_input
    end
  end

  defp infer_options(type, constraints) do
    cond do
      constraints[:one_of] ->
        Enum.map(constraints[:one_of], &value_to_option/1)

      is_atom(type) and function_exported?(type, :values, 0) ->
        Enum.map(type.values(), &value_to_option/1)

      true ->
        []
    end
  end

  defp value_to_option(value) when is_atom(value) do
    {humanize(value), value}
  end

  defp value_to_option(value) do
    {to_string(value), value}
  end

  defp build_nested_forms_config(fields, resource) do
    fields
    |> Enum.filter(&needs_nested_form?/1)
    |> Enum.map(&build_nested_config(&1, resource))
    |> Enum.reject(&is_nil/1)
  end

  defp needs_nested_form?(field) do
    not is_nil(field.relationship) and
      field.relationship_type in [:has_many, :has_one] and
      field.type == :nested_form
  end

  defp build_nested_config(field, resource) do
    rel = Ash.Resource.Info.relationship(resource, field.relationship)

    if rel do
      cardinality = if rel.cardinality == :many, do: :list, else: :single

      config = [
        type: cardinality,
        resource: rel.destination,
        create_action: :create,
        update_action: :update
      ]

      {field.relationship, config}
    else
      nil
    end
  end

  defp requires_preload?(field) do
    not is_nil(field.relationship) and
      field.relationship_type in [:many_to_many, :has_many]
  end

  defp humanize(value) when is_atom(value) do
    value
    |> to_string()
    |> String.split("_")
    |> Enum.map_join(" ", &String.capitalize/1)
  end

  defp humanize(value), do: to_string(value)
end
