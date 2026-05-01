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
  * `:file_upload` - File upload (bridged to Phoenix LiveView `allow_upload`)
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
            | :checkbox_group
            | :checkbox
            | :toggle
            | :number
            | :email
            | :password
            | :date
            | :datetime
            | :hidden
            | :url
            | :tel
            | :file_upload,
          required: boolean(),
          options: list(),
          class: String.t() | nil,
          wrapper_class: String.t() | nil,
          hint: String.t() | nil,
          description: String.t() | nil,
          autocomplete: String.t() | nil,
          autofocus: boolean(),
          readonly: boolean(),
          disabled: boolean(),
          min: number() | String.t() | nil,
          max: number() | String.t() | nil,
          step: number() | String.t() | nil,
          pattern: String.t() | nil,
          rows: pos_integer() | nil,
          maxlength: pos_integer() | nil,
          inputmode: String.t() | nil,
          prefix: String.t() | nil,
          suffix: String.t() | nil,
          relationship: atom() | nil,
          relationship_type: atom() | nil,
          destination_resource: module() | nil,
          accept: :any | [String.t()] | String.t() | atom() | nil,
          max_files: pos_integer() | nil,
          max_file_size: pos_integer() | {pos_integer(), atom()} | nil,
          cloud: module() | nil,
          bucket: String.t() | nil,
          auto_upload: boolean() | nil,
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
    :description,
    :autocomplete,
    :min,
    :max,
    :step,
    :pattern,
    :rows,
    :maxlength,
    :inputmode,
    :prefix,
    :suffix,
    :relationship,
    :relationship_type,
    :destination_resource,
    :accept,
    :max_files,
    :max_file_size,
    :cloud,
    :bucket,
    :auto_upload,
    :__spark_metadata__,
    type: :text_input,
    required: false,
    autofocus: false,
    readonly: false,
    disabled: false,
    options: [],
    opts: []
  ]
end
