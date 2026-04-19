defmodule AshFormBuilder.NestedForm do
  @moduledoc """
  Represents a nested relationship form declared via the `nested` DSL entity.

  Stores its child `Field` structs in `fields` and the resolved destination
  resource (filled in by the transformer after reading Ash relationship metadata).
  """

  defstruct [
    :name,
    :relationship,
    :label,
    :class,
    :destination_resource,
    :__spark_metadata__,
    cardinality: :many,
    add_label: "Add",
    remove_label: "Remove",
    create_action: :create,
    update_action: :update,
    fields: []
  ]
end
