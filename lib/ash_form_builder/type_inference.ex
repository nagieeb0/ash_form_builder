defmodule AshFormBuilder.TypeInference do
  @moduledoc """
  Infers `AshFormBuilder.Field` structs from an Ash resource action at runtime.

  Called by `AshFormBuilder.Info.effective_fields/1` to produce auto-inferred
  fields for any attribute in the action's `accept` list or `arguments` list
  that does not already have an explicit DSL override.
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
  Returns inferred `Field` structs for the given resource action.

  Fields are produced in the order they appear in `action.accept`, followed
  by action arguments (if any).
  """
  @spec infer_fields(module(), atom()) :: [Field.t()]
  def infer_fields(resource, action_name) do
    action = Ash.Resource.Info.action(resource, action_name)

    if is_nil(action) do
      []
    else
      accepted = action.accept || []
      arguments = action.arguments || []

      attr_fields =
        accepted
        |> Enum.map(&Ash.Resource.Info.attribute(resource, &1))
        |> Enum.reject(&is_nil/1)
        |> Enum.map(&infer_from_attribute/1)

      arg_fields = Enum.map(arguments, &infer_from_argument/1)

      attr_fields ++ arg_fields
    end
  end

  # ---------------------------------------------------------------------------
  # Private
  # ---------------------------------------------------------------------------

  defp infer_from_attribute(attr) do
    %Field{
      name: attr.name,
      label: humanize(attr.name),
      type: infer_type(attr.type, attr.constraints || []),
      required: !attr.allow_nil? && is_nil(attr.default),
      options: infer_options(attr.type, attr.constraints || [])
    }
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

  defp humanize(value) when is_atom(value) do
    value
    |> to_string()
    |> String.split("_")
    |> Enum.map_join(" ", &String.capitalize/1)
  end

  defp humanize(value), do: to_string(value)
end
