defmodule AshFormBuilder.Dsl do
  @moduledoc false

  # ---------------------------------------------------------------------------
  # field entity — a single form input
  # ---------------------------------------------------------------------------

  @field %Spark.Dsl.Entity{
    name: :field,
    target: AshFormBuilder.Field,
    args: [:name],
    schema: [
      name: [
        type: :atom,
        required: true,
        doc: "The attribute name on the resource."
      ],
      label: [
        type: :string,
        doc: "Human-readable label rendered above the input."
      ],
      type: [
        type:
          {:one_of,
           [
             :text_input,
             :textarea,
             :select,
             :checkbox,
             :number,
             :email,
             :password,
             :date,
             :datetime,
             :hidden,
             :url,
             :tel
           ]},
        default: :text_input,
        doc: "The HTML input type to render."
      ],
      placeholder: [
        type: :string,
        doc: "Placeholder text for the input."
      ],
      required: [
        type: :boolean,
        default: false,
        doc: "Whether to show a required indicator."
      ],
      options: [
        type: {:list, :any},
        default: [],
        doc: "Options for `:select` fields. Accepts `[value]` or `[{label, value}]`."
      ],
      class: [
        type: :string,
        doc: "Extra CSS class(es) applied to the `<input>` / `<select>` / `<textarea>` element."
      ],
      wrapper_class: [
        type: :string,
        doc: "Extra CSS class(es) applied to the wrapping `<div>`."
      ],
      hint: [
        type: :string,
        doc: "Helper text rendered below the input."
      ]
    ]
  }

  # ---------------------------------------------------------------------------
  # nested entity — a nested relationship form block
  # ---------------------------------------------------------------------------

  @nested_form %Spark.Dsl.Entity{
    name: :nested,
    target: AshFormBuilder.NestedForm,
    args: [:name],
    entities: [fields: [@field]],
    schema: [
      name: [
        type: :atom,
        required: true,
        doc: "Identifier for the nested form — usually matches the relationship name."
      ],
      relationship: [
        type: :atom,
        doc: "The relationship name on the parent resource. Defaults to `name`."
      ],
      cardinality: [
        type: {:one_of, [:one, :many]},
        default: :many,
        doc: "`:many` renders an add/remove list; `:one` renders a single sub-form."
      ],
      label: [
        type: :string,
        doc: "Optional `<legend>` label for the nested fieldset."
      ],
      add_label: [
        type: :string,
        default: "Add",
        doc: "Text on the add button (`:many` cardinality only)."
      ],
      remove_label: [
        type: :string,
        default: "Remove",
        doc: "Text on the remove button."
      ],
      create_action: [
        type: :atom,
        default: :create,
        doc: "The create action on the nested resource used by AshPhoenix.Form."
      ],
      update_action: [
        type: :atom,
        default: :update,
        doc: "The update action on the nested resource used by AshPhoenix.Form."
      ],
      class: [
        type: :string,
        doc: "Extra CSS class(es) applied to the nested `<fieldset>`."
      ]
    ]
  }

  # ---------------------------------------------------------------------------
  # form section — top-level container
  # ---------------------------------------------------------------------------

  @form %Spark.Dsl.Section{
    name: :form,
    describe: "Declares the auto-generated LiveView form for this Ash resource.",
    entities: [@field, @nested_form],
    schema: [
      action: [
        type: :atom,
        required: true,
        doc: "The Ash action this form targets, e.g. `:create` or `:update`."
      ],
      submit_label: [
        type: :string,
        default: "Submit",
        doc: "Label for the submit button."
      ],
      module: [
        type: :atom,
        doc: "Override the auto-generated helper module name (default: `Resource.Form`)."
      ],
      form_id: [
        type: :string,
        doc: "HTML `id` attribute for the `<form>` element."
      ],
      wrapper_class: [
        type: :string,
        default: "space-y-4",
        doc: "CSS class applied to the fields wrapper `<div>`."
      ]
    ]
  }

  def sections, do: [@form]

  def transformers do
    [
      AshFormBuilder.Transformers.ResolveNestedResources,
      AshFormBuilder.Transformers.GenerateFormModule
    ]
  end
end
