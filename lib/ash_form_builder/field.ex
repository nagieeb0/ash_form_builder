defmodule AshFormBuilder.Field do
  @moduledoc """
  Represents a single form field declared via the `field` DSL entity.

  ## Relationship Fields

  When a field represents a relationship (e.g., `many_to_many`), the following
  fields are populated:

  * `:relationship` - The relationship name (atom)
  * `:relationship_type` - The type of relationship (`:many_to_many`, `:has_many`, etc.)
  * `:destination_resource` - The related resource module
  * `:opts` - Custom options for UI components (search events, preload options, etc.)

  ## Types

  * `:text_input` - Standard text input
  * `:textarea` - Multi-line text area
  * `:select` - Single-select dropdown
  * `:multiselect_combobox` - Many-to-many searchable multi-select (MishkaChelekom combobox)
  * `:checkbox` - Boolean checkbox
  * `:number` - Numeric input
  * `:email` - Email input
  * `:password` - Password input
  * `:date` - Date picker
  * `:datetime` - DateTime picker
  * `:hidden` - Hidden input
  * `:url` - URL input
  * `:tel` - Telephone input
  """

  @type t :: %__MODULE__{
          name: atom(),
          label: String.t() | nil,
          placeholder: String.t() | nil,
          type:
            :text_input
            | :textarea
            | :select
            | :multiselect_combobox
            | :checkbox
            | :number
            | :email
            | :password
            | :date
            | :datetime
            | :hidden
            | :url
            | :tel,
          required: boolean(),
          options: list(),
          class: String.t() | nil,
          wrapper_class: String.t() | nil,
          hint: String.t() | nil,
          relationship: atom() | nil,
          relationship_type: atom() | nil,
          destination_resource: module() | nil,
          opts: keyword(),
          __spark_metadata__: map() | nil
        }

  defstruct [
    :name,
    :label,
    :placeholder,
    :class,
    :wrapper_class,
    :hint,
    :relationship,
    :relationship_type,
    :destination_resource,
    :__spark_metadata__,
    type: :text_input,
    required: false,
    options: [],
    opts: []
  ]
end
