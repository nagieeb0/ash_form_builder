defmodule AshFormBuilder.Transformers.ResolveNestedResources do
  @moduledoc """
  Resolves the `destination_resource` for every `NestedForm` entity by
  reading Ash relationship metadata on the parent resource.

  Persists a `%{nested_name => destination_resource}` map under
  `:ash_form_builder_nested_resources` so that `GenerateFormModule` and
  `AshFormBuilder.Info` can consume it without repeating the lookup.

  Must run before `GenerateFormModule`.
  """

  use Spark.Dsl.Transformer

  alias Spark.Dsl.Transformer

  @impl Spark.Dsl.Transformer
  def before?(_), do: true

  @impl Spark.Dsl.Transformer
  def after?(_), do: false

  @impl Spark.Dsl.Transformer
  def transform(dsl_state) do
    resource = Transformer.get_persisted(dsl_state, :module)

    # Read relationships from dsl_state — the resource module is not yet compiled
    # at transformer time, so Ash.Resource.Info.relationship/2 cannot be used here.
    ash_relationships = Spark.Dsl.Extension.get_entities(dsl_state, [:relationships])

    form_entities = Spark.Dsl.Extension.get_entities(dsl_state, [:form])

    nested_map =
      form_entities
      |> Enum.filter(&is_struct(&1, AshFormBuilder.NestedForm))
      |> Map.new(fn nested ->
        rel_name = nested.relationship || nested.name
        destination = resolve_destination!(nested, rel_name, ash_relationships, resource)
        {nested.name, destination}
      end)

    dsl_state = Transformer.persist(dsl_state, :ash_form_builder_nested_resources, nested_map)
    {:ok, dsl_state}
  end

  defp resolve_destination!(nested, rel_name, ash_relationships, resource) do
    case Enum.find(ash_relationships, &(&1.name == rel_name)) do
      nil ->
        raise Spark.Error.DslError,
          module: resource,
          path: [:form, :nested, nested.name],
          message:
            "No relationship `#{rel_name}` found on #{inspect(resource)}. " <>
              "Ensure the relationship is declared before the `form` block."

      relationship ->
        relationship.destination
    end
  end
end
