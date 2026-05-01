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
             :checkbox_group,
             :checkbox,
             :toggle,
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

        Boolean / many_to_many types:
        * `:toggle` (default for boolean attributes) - Animated switch.
        * `:checkbox` - Standard square checkbox (use this to override the toggle default).
        * `:checkbox_group` (default for many_to_many) - Vertical list of checkboxes
          backed by the relationship's options.
        * `:multiselect_combobox` - Searchable multi-select for many_to_many. Set
          this explicitly when you need search/creatable behavior.

        Other special types:
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
      description: [
        type: :string,
        doc:
          "Longer descriptive text rendered above the input (rendered between the label and the field by themes that support it)."
      ],
      autocomplete: [
        type: :string,
        doc:
          "HTML `autocomplete` attribute (`\"email\"`, `\"name\"`, `\"new-password\"`, `\"off\"`, etc.)."
      ],
      autofocus: [
        type: :boolean,
        default: false,
        doc: "If true, the input renders with the `autofocus` attribute."
      ],
      readonly: [
        type: :boolean,
        default: false,
        doc: "If true, the input renders with the `readonly` attribute."
      ],
      disabled: [
        type: :boolean,
        default: false,
        doc: "If true, the input renders with the `disabled` attribute."
      ],
      min: [
        type: {:or, [:integer, :float, :string]},
        doc:
          "HTML `min` attribute. Useful for `:number`, `:date`, and `:datetime` fields. Strings are passed through verbatim."
      ],
      max: [
        type: {:or, [:integer, :float, :string]},
        doc: "HTML `max` attribute (mirrors `min`)."
      ],
      step: [
        type: {:or, [:integer, :float, :string]},
        doc: "HTML `step` attribute. For `:number` fields use e.g. `0.01` to allow two decimals."
      ],
      pattern: [
        type: :string,
        doc: "HTML `pattern` regex constraint applied to text-like inputs."
      ],
      rows: [
        type: :pos_integer,
        doc: "Number of visible rows for `:textarea` fields (default `4`)."
      ],
      maxlength: [
        type: :pos_integer,
        doc: "HTML `maxlength` attribute for text-like inputs."
      ],
      inputmode: [
        type: :string,
        doc:
          "Hints the on-screen keyboard for mobile devices (`\"numeric\"`, `\"decimal\"`, `\"tel\"`, `\"email\"`, …)."
      ],
      prefix: [
        type: :string,
        doc:
          "Short text or character rendered immediately before the input (e.g. `\"$\"`, `\"https://\"`). Themes that support it will pin it inside the input's left affix."
      ],
      suffix: [
        type: :string,
        doc:
          "Short text or character rendered immediately after the input (e.g. `\"kg\"`, `\".com\"`)."
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
      accept: [
        type: {:or, [{:literal, :any}, {:list, :string}, :string]},
        doc: """
        File-upload accept filter. Pass `:any` (default) to accept any file,
        a list of extensions / mime types like `~w(.jpg .png image/webp)`, or
        a shorthand atom (`:images`, `:documents`, `:audio`, `:video`).
        Only meaningful for `type: :file_upload`.
        """
      ],
      max_files: [
        type: :pos_integer,
        doc:
          "Max number of files allowed for `type: :file_upload` (Phoenix `max_entries`). Default 1."
      ],
      max_file_size: [
        type: {:or, [:pos_integer, {:tuple, [:pos_integer, :atom]}]},
        doc: """
        Max upload size for `type: :file_upload`. Either an integer (bytes) or
        a `{n, unit}` tuple where unit is `:kb`, `:mb`, or `:gb`. Default 8 MB.
        """
      ],
      cloud: [
        type: :atom,
        doc:
          "Module implementing the `Buckets.Cloud` behaviour to use for storing uploads. Optional — defaults to in-process consumption."
      ],
      bucket: [
        type: :string,
        doc: "Bucket / prefix name passed to the cloud module. Optional."
      ],
      auto_upload: [
        type: :boolean,
        doc: "If true, mirrors Phoenix LiveView's `auto_upload: true` (defaults to false)."
      ],
      opts: [
        type: :keyword_list,
        default: [],
        doc: """
        Escape hatch for component-specific options that don't have a first-class
        DSL field yet.

        For `:multiselect_combobox`:
        * `search_event` - Event name for searching (e.g., "search_doctors")
        * `search_param` - Query param name for search (default: "query")
        * `debounce` - Search debounce in ms (default: 300)
        * `preload_options` - Preload initial options as `[{label, value}]`
        * `label_key` - Field to use as label (default: `:name`)
        * `value_key` - Field to use as value (default: `:id`)
        * `creatable` - Allow creating new items via combobox (default: false)
        * `create_action` - Action to use for creating new items (default: :create)
        * `create_label` - Label for the create button (default: "Create \"{value}\"")

        For `:file_upload`, the first-class fields `accept`, `max_files`,
        `max_file_size`, `cloud`, `bucket`, `auto_upload` should be preferred.
        Legacy nested form `opts: [upload: [...]]` is still honoured.
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
      ],
      max_count: [
        type: :pos_integer,
        doc: """
        Optional cap on the number of child entries the user can add. The Add
        button is disabled (and the count label flips to "X of N") once this
        many entries are present.

        Tip: derive this from your Ash action argument constraints, e.g.
        `argument :subtasks, {:array, :map}, constraints: [max_length: 5]`,
        and pass `max_count 5` here so the UI matches the changeset rule.
        """
      ],
      min_count: [
        type: :non_neg_integer,
        default: 0,
        doc:
          "Optional minimum number of entries. The Remove button is disabled when at the minimum."
      ]
    ]
  }

  # ---------------------------------------------------------------------------
  # form entity — one per Ash action
  # ---------------------------------------------------------------------------

  @form %Spark.Dsl.Entity{
    name: :form,
    target: AshFormBuilder.FormConfig,
    args: [:action],
    entities: [entities: [@field, @nested_form]],
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
        doc: "Override the auto-generated helper module name (default: derived from action)."
      ],
      form_id: [
        type: :string,
        doc: "HTML `id` attribute for the `<form>` element."
      ],
      wrapper_class: [
        type: :string,
        default: "space-y-4",
        doc: "CSS class applied to the fields wrapper `<div>`."
      ],
      theme: [
        type: :atom,
        doc: """
        Theme to use for this form. Accepts a module
        (`AshFormBuilder.Themes.Shadcn`) or a short atom (`:shadcn`,
        `:default`, `:glassmorphism`, `:mishka`, or any user-registered
        atom under `config :ash_form_builder, :themes, ...`).

        Falls back to the `:ash_form_builder, :theme` app env, then to
        `AshFormBuilder.Themes.Default`.
        """
      ],
      accent: [
        type:
          {:one_of,
           [
             :blue,
             :indigo,
             :violet,
             :purple,
             :pink,
             :rose,
             :red,
             :orange,
             :amber,
             :yellow,
             :lime,
             :green,
             :emerald,
             :teal,
             :cyan,
             :sky,
             :slate,
             :gray,
             :zinc
           ]},
        default: :indigo,
        doc: "Accent Tailwind color used for focus rings, primary buttons, and selected states."
      ],
      transitions: [
        type: {:one_of, [:none, :subtle, :smooth]},
        default: :subtle,
        doc:
          "Animation intensity. `:none` disables transitions, `:subtle` (default) adds 150ms color/shadow transitions, `:smooth` adds 200ms with translate."
      ]
    ]
  }

  # ---------------------------------------------------------------------------
  # forms section — top-level container holding one form per action
  # ---------------------------------------------------------------------------

  @forms %Spark.Dsl.Section{
    name: :forms,
    describe: """
    Declares one auto-generated LiveView form per Ash action.

        forms do
          form :create do
            submit_label "Create Task"
            field :title do
              label "Task Title"
              required true
            end
          end

          form :update do
            submit_label "Update Task"
          end
        end
    """,
    entities: [@form]
  }

  def sections, do: [@forms]

  def transformers do
    [
      AshFormBuilder.Transformers.ResolveNestedResources,
      AshFormBuilder.Transformers.GenerateFormModule
    ]
  end
end
