defmodule AshFormBuilder.TypeInference do
  @moduledoc """
  Infers `AshFormBuilder.Field` structs from an Ash resource action at runtime.

  **DEPRECATED**: This module is kept for backward compatibility.
  Please use `AshFormBuilder.Infer` for new code.

  Called by `AshFormBuilder.Info.effective_fields/1` to produce auto-inferred
  fields for any attribute in the action's `accept` list or `arguments` list
  that does not already have an explicit DSL override.

  ## Relationship Support

  Now delegates to `AshFormBuilder.Infer` which supports:
  * Auto-detection of many_to_many relationships
  * Mapping many_to_many to `:multiselect_combobox` UI type
  * Full relationship metadata in inferred fields
  """

  alias AshFormBuilder.Field

  @doc """
  Returns inferred `Field` structs for the given resource action.

  Fields are produced in the order they appear in `action.accept`, followed
  by action arguments (if any).

  ## Relationship Detection

  When the action's `accept` list includes relationship names:
  * `many_to_many` relationships are mapped to `:multiselect_combobox` type
  * Relationship metadata (`relationship`, `relationship_type`, `destination_resource`)
    is populated on the field struct
  """
  @spec infer_fields(module(), atom()) :: [Field.t()]
  def infer_fields(resource, action_name) do
    # Delegate to the comprehensive Infer module
    AshFormBuilder.Infer.infer_fields(resource, action_name,
      ignore_fields: [:id, :inserted_at, :updated_at],
      include_timestamps: false
    )
  end

  @doc """
  Infers a field from a single attribute (backward compatibility).
  """
  @spec infer_from_attribute(Ash.Resource.Attribute.t()) :: Field.t()
  def infer_from_attribute(attr) do
    %Field{
      name: attr.name,
      label: humanize(attr.name),
      type: infer_type_from_attr_type(attr.type, attr.constraints || []),
      required: !attr.allow_nil? && is_nil(attr.default),
      options: infer_options_from_constraints(attr.type, attr.constraints || [])
    }
  end

  @doc """
  Infers a field from a single argument (backward compatibility).
  """
  @spec infer_from_argument(Ash.Resource.Actions.Argument.t()) :: Field.t()
  def infer_from_argument(arg) do
    %Field{
      name: arg.name,
      label: humanize(arg.name),
      type: infer_type_from_attr_type(arg.type, arg.constraints || []),
      required: !arg.allow_nil?,
      options: infer_options_from_constraints(arg.type, arg.constraints || [])
    }
  end

  # ---------------------------------------------------------------------------
  # Private Helpers (kept for backward compatibility)
  # ---------------------------------------------------------------------------

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

  defp infer_type_from_attr_type(type, constraints) do
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

  defp infer_options_from_constraints(type, constraints) do
    cond do
      constraints[:one_of] ->
        Enum.map(constraints[:one_of], fn v -> {humanize(v), v} end)

      is_atom(type) && function_exported?(type, :values, 0) ->
        Enum.map(type.values(), fn v -> {humanize(v), v} end)

      true ->
        []
    end
  end

  defp humanize(value) when is_atom(value) do
    value
    |> to_string()
    |> String.split("_")
    |> Enum.map_join(" ", &String.capitalize/1)
  end

  defp humanize(value), do: to_string(value)
end
