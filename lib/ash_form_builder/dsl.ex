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
        doc: "The attribute name on the resource (or relationship name for many_to_many)."
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
             :multiselect_combobox,
             :checkbox,
             :number,
             :email,
             :password,
             :date,
             :datetime,
             :hidden,
             :url,
             :tel,
             :file_upload
           ]},
        default: :text_input,
        doc: """
        The HTML input type to render.

        Special types:
        * `:multiselect_combobox` - For many_to_many relationships. Uses a searchable
          multi-select combobox (MishkaChelekom). Supports `opts` for customization.
        * `:file_upload` - Phoenix LiveView file upload. Configure via `opts`:
          `[upload: [cloud: MyApp.Cloud, max_entries: 1, max_file_size: 10_000_000, accept: ~w(.jpg .png)]]`
        """
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
        doc: """
        Options for `:select` or `:multiselect_combobox` fields.
        Accepts `[value]`, `[{label, value}]`, or `{module, function, args}` for dynamic loading.
        """
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
      ],
      relationship: [
        type: :atom,
        doc: "For relationship fields: the relationship name (auto-inferred for many_to_many)."
      ],
      relationship_type: [
        type: :atom,
        doc: "The type of relationship (`:many_to_many`, `:has_many`, etc.). Auto-inferred."
      ],
      destination_resource: [
        type: :atom,
        doc: "For relationship fields: the related resource module. Auto-inferred."
      ],
      opts: [
        type: :keyword_list,
        default: [],
        doc: """
        Custom options for UI components. For `:multiselect_combobox`, supports:
        * `search_event` - Event name for searching (e.g., "search_doctors")
        * `search_param` - Query param name for search (default: "query")
        * `debounce` - Search debounce in ms (default: 300)
        * `preload_options` - Preload initial options as `[{label, value}]`
        * `label_key` - Field to use as label (default: `:name`)
        * `value_key` - Field to use as value (default: `:id`)
        * `creatable` - Allow creating new items via combobox (default: false)
        * `create_action` - Action to use for creating new items (default: :create)
        * `create_label` - Label for the create button (default: "Create \"{value}\"")
        """
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
      ignore_fields: [
        type: {:list, :atom},
        default: [:id, :inserted_at, :updated_at],
        doc:
          "Fields to exclude from auto-inference. Use this to hide fields without writing full field blocks."
      ],
      field_order: [
        type: {:list, :atom},
        doc:
          "Custom ordering for fields. Fields listed first appear first. Fields not listed appear after in default order."
      ],
      include_timestamps: [
        type: :boolean,
        default: false,
        doc:
          "Whether to include :inserted_at and :updated_at fields. Set to true if you need timestamp inputs."
      ],
      creatable: [
        type: :boolean,
        default: false,
        doc:
          "Enable creatable combobox for all many_to_many relationships. Individual fields can override this."
      ],
      create_action: [
        type: :atom,
        default: :create,
        doc: "Default action to use for creating new items in creatable comboboxes."
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
