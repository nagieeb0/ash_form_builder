defmodule AshFormBuilder.Infer do
  @moduledoc """
  True Auto-Inference Engine for AshFormBuilder.

  Dynamically infers form field definitions from Ash resource metadata at runtime.
  Reads the `accept` list, arguments, and relationships via `Ash.Resource.Info`.

  ## Key Capabilities

  * **Type Mapping**: Maps Ash types to appropriate UI types
  * **Relationship Detection**: Auto-detects many_to_many relationships and maps them
    to `:multiselect_combobox` UI type
  * **Smart Defaults**: Infers labels, required status, and options from constraints

  ## Usage

      # Infer all fields for a resource action
      fields = AshFormBuilder.Infer.infer_fields(MyApp.Clinic, :create)

      # Infer with custom overrides
      fields = AshFormBuilder.Infer.infer_fields(MyApp.Clinic, :create,
        many_to_many_as: :multiselect_combobox,
        ignore_fields: [:id, :inserted_at]
      )

  ## Relationship Handling

  When a `many_to_many` relationship is detected in the action's `accept` list:

  1. The field type is set to `:multiselect_combobox`
  2. `relationship`, `relationship_type`, and `destination_resource` are populated
  3. Default opts are set for the combobox (label_key: :name, value_key: :id)

  This enables seamless UI rendering with searchable multi-select for related records.
  """

  alias AshFormBuilder.Field

  # Ash type module → form field type
  @type_map %{
    Ash.Type.String => :text_input,
    :string => :text_input,
    Ash.Type.CiString => :text_input,
    :ci_string => :text_input,
    Ash.Type.Boolean => :checkbox,
    :boolean => :checkbox,
    Ash.Type.Integer => :number,
    :integer => :number,
    Ash.Type.Decimal => :number,
    :decimal => :number,
    Ash.Type.Float => :number,
    :float => :number,
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
    Ash.Type.URL => :url,
    :url => :url
  }

  @doc """
  Infers `Field` structs for the given resource action.

  ## Options

  * `:many_to_many_as` - UI type for many_to_many relationships (default: `:multiselect_combobox`)
  * `:ignore_fields` - List of field names to skip (default: `[:id, :inserted_at, :updated_at]`)
  * `:include_timestamps` - Whether to include timestamp fields (default: `false`)

  ## Returns

  List of `%AshFormBuilder.Field{}` structs in the order they should be rendered.
  """
  @spec infer_fields(module(), atom(), keyword()) :: [Field.t()]
  def infer_fields(resource, action_name, opts \\ []) do
    action = Ash.Resource.Info.action(resource, action_name)

    if is_nil(action) do
      []
    else
      ignore_fields = Keyword.get(opts, :ignore_fields, [:id, :inserted_at, :updated_at])
      include_timestamps = Keyword.get(opts, :include_timestamps, false)

      # Get all relevant fields from accept list
      accepted = action.accept || []

      # Filter out ignored fields unless timestamps are included
      filtered_accepted =
        if include_timestamps do
          accepted
        else
          Enum.reject(accepted, &(&1 in ignore_fields))
        end

      # Build fields from accept list (handles both attributes and relationships)
      accept_fields =
        filtered_accepted
        |> Enum.map(&infer_from_accept(resource, &1, opts))
        |> Enum.reject(&is_nil/1)

      # Build fields from action arguments
      arguments = action.arguments || []
      arg_fields = Enum.map(arguments, &infer_from_argument/1)

      accept_fields ++ arg_fields
    end
  end

  @doc """
  Infers a complete form schema including nested forms configuration.

  Returns a map with:
  * `:fields` - List of Field structs
  * `:nested_forms` - Keyword list for AshPhoenix.Form `:forms` option
  * `:action` - The action name
  * `:resource` - The resource module
  * `:required_preloads` - List of relationships to preload for update forms

  ## Usage

      schema = AshFormBuilder.Infer.infer_schema(MyApp.Clinic, :create)

      # Use in a LiveView
      form =
        AshPhoenix.Form.for_create(
          schema.resource,
          schema.action,
          forms: schema.nested_forms
        )

  ## Required Preloads for Updates

  When inferring an update action, this function detects which relationships
  need to be preloaded for the form to work correctly (e.g., many_to_many
  relationships that are managed through the form).
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

    # Separate relationship fields that need nested forms
    nested_forms = build_nested_forms_config(fields, resource)

    # Detect required preloads for update actions
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
  Detects which relationships need to be preloaded for update forms.

  This is crucial for many_to_many relationships and nested forms to display
  existing data correctly when editing a record.
  """
  @spec detect_required_preloads([Field.t()], module(), atom()) :: [atom()]
  def detect_required_preloads(fields, resource, action_name) do
    action = Ash.Resource.Info.action(resource, action_name)

    # Only preloads needed for update/destroy actions
    if is_nil(action) or action.type not in [:update, :destroy] do
      []
    else
      # Collect relationship fields that are in the accept list
      fields
      |> Enum.filter(fn field ->
        not is_nil(field.relationship) and field.type == :multiselect_combobox
      end)
      |> Enum.map(& &1.relationship)
      |> Enum.uniq()
    end
  end

  @doc """
  Detects if a field name represents a relationship on the resource.

  Returns `{:relationship, relationship}` or `:attribute`.
  """
  @spec detect_field_type(module(), atom()) :: :attribute | {:relationship, Ash.Resource.Relationships.relationship()}
  def detect_field_type(resource, field_name) do
    case Ash.Resource.Info.relationship(resource, field_name) do
      nil -> :attribute
      rel -> {:relationship, rel}
    end
  end

  # ---------------------------------------------------------------------------
  # Private
  # ---------------------------------------------------------------------------

  defp infer_from_accept(resource, field_name, opts) do
    case detect_field_type(resource, field_name) do
      :attribute ->
        infer_from_attribute(resource, field_name)

      {:relationship, rel} ->
        infer_from_relationship(rel, opts)
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
        required: !attr.allow_nil? && is_nil(attr.default),
        options: infer_options(attr.type, attr.constraints || [])
      }
    end
  end

  defp infer_from_relationship(rel, opts) do
    many_to_many_type = Keyword.get(opts, :many_to_many_as, :multiselect_combobox)

    case rel.type do
      :many_to_many ->
        %Field{
          name: rel.name,
          label: humanize(rel.name),
          type: many_to_many_type,
          required: false,
          options: [],
          relationship: rel.name,
          relationship_type: :many_to_many,
          destination_resource: rel.destination,
          opts: default_combobox_opts(rel.destination)
        }

      :has_many ->
        # has_many typically uses nested forms, not direct fields
        nil

      :belongs_to ->
        # belongs_to can use a select or combobox depending on options count
        %Field{
          name: rel.name,
          label: humanize(rel.name),
          type: :select,
          required: false,
          options: [],
          relationship: rel.name,
          relationship_type: :belongs_to,
          destination_resource: rel.destination,
          opts: default_combobox_opts(rel.destination)
        }

      _other ->
        nil
    end
  end

  defp infer_from_argument(arg) do
    %Field{
      name: arg.name,
      label: humanize(arg.name),
      type: infer_type(arg.type, arg.constraints || []),
      required: !arg.allow_nil?,
      options: infer_options(arg.type, arg.constraints || [])
    }
  end

  defp infer_type(type, constraints) do
    cond do
      Map.has_key?(@type_map, type) ->
        Map.get(@type_map, type)

      constraints[:one_of] ->
        :select

      # Ash.Type.Atom with one_of constraint
      type == :atom && constraints[:one_of] ->
        :select

      # Ash.Type.Enum modules expose values/0
      is_atom(type) && function_exported?(type, :values, 0) ->
        :select

      true ->
        :text_input
    end
  end

  defp infer_options(type, constraints) do
    cond do
      constraints[:one_of] ->
        Enum.map(constraints[:one_of], fn v -> {humanize(v), v} end)

      is_atom(type) && function_exported?(type, :values, 0) ->
        Enum.map(type.values(), fn v -> {humanize(v), v} end)

      true ->
        []
    end
  end

  defp default_combobox_opts(destination_resource) do
    # Infer label/value keys based on common Ash resource conventions
    label_key = if field_exists?(destination_resource, :name), do: :name, else: :id
    value_key = :id

    [
      label_key: label_key,
      value_key: value_key,
      search_param: "query",
      debounce: 300,
      creatable: false,
      create_action: :create
    ]
  end

  defp field_exists?(resource, field_name) do
    not is_nil(Ash.Resource.Info.attribute(resource, field_name))
  end

  defp build_nested_forms_config(fields, resource) do
    fields
    |> Enum.reject(&is_nil/1)
    |> Enum.filter(fn field ->
      # Only build nested config for relationship fields that aren't comboboxes
      not is_nil(field.relationship) and field.type != :multiselect_combobox
    end)
    |> Enum.map(fn field ->
      rel = Ash.Resource.Info.relationship(resource, field.relationship)

      if rel do
        type = if rel.cardinality == :many, do: :list, else: :single

        config = [
          type: type,
          resource: rel.destination,
          create_action: :create,
          update_action: :update
        ]

        {field.name, config}
      else
        nil
      end
    end)
    |> Enum.reject(&is_nil/1)
  end

  defp humanize(value) when is_atom(value) do
    value
    |> to_string()
    |> String.split("_")
    |> Enum.map_join(" ", &String.capitalize/1)
  end

  defp humanize(value), do: to_string(value)
end
