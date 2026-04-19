defmodule AshFormBuilder.Field do
  @moduledoc """
  Represents a single form field declared via the `field` DSL entity.
  """

  defstruct [
    :name,
    :label,
    :placeholder,
    :class,
    :wrapper_class,
    :hint,
    :__spark_metadata__,
    type: :text_input,
    required: false,
    options: []
  ]
end
