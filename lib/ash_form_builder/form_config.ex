defmodule AshFormBuilder.FormConfig do
  @moduledoc """
  Struct representing one form declaration inside a `forms do` block.

  Each `form :action do ... end` entity in the DSL produces one of these,
  carrying the per-action configuration (submit label, fields, nested
  forms, ignore list, etc.).
  """

  defstruct [
    :action,
    :module,
    :form_id,
    :field_order,
    :theme,
    __spark_metadata__: nil,
    submit_label: "Submit",
    ignore_fields: [:id, :inserted_at, :updated_at],
    include_timestamps: false,
    creatable: false,
    create_action: :create,
    wrapper_class: "space-y-4",
    accent: :indigo,
    transitions: :subtle,
    entities: []
  ]

  @type t :: %__MODULE__{
          action: atom(),
          module: module() | nil,
          form_id: String.t() | nil,
          field_order: [atom()] | nil,
          theme: module() | nil,
          submit_label: String.t(),
          ignore_fields: [atom()],
          include_timestamps: boolean(),
          creatable: boolean(),
          create_action: atom(),
          wrapper_class: String.t(),
          accent: atom(),
          transitions: :none | :subtle | :smooth,
          entities: list()
        }
end
