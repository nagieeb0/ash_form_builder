defmodule AshFormBuilder.Transformers.GenerateFormModule do
  @moduledoc """
  Generates a `Resource.Form` helper module at compile time for every
  resource that declares one or more forms in `forms do ... end`.

  The generated module exposes one function per declared action:

    * `for_<action>/1` for create / read actions
    * `for_<action>/2` for update / destroy actions (record + opts)

  Plus introspection helpers:

    * `actions/0`        — list of declared action atoms
    * `schema/1`         — schema for the given action
    * `nested_forms/1`   — AshPhoenix.Form `:forms` config for an action
    * `required_preloads/1` — relationships to preload when editing
  """

  use Spark.Dsl.Transformer

  alias Spark.Dsl.{Extension, Transformer}

  @impl Spark.Dsl.Transformer
  def before?(_), do: false

  @impl Spark.Dsl.Transformer
  def after?(AshFormBuilder.Transformers.ResolveNestedResources), do: true
  def after?(_), do: false

  @impl Spark.Dsl.Transformer
  def transform(dsl_state) do
    resource = Transformer.get_persisted(dsl_state, :module)
    forms = Extension.get_entities(dsl_state, [:forms])

    if forms != [] do
      nested_map =
        Transformer.get_persisted(dsl_state, :ash_form_builder_nested_resources) || %{}

      module_name = derive_form_module(resource, forms)

      action_specs =
        Enum.map(forms, fn form ->
          entities = form.entities

          nested_config = build_nested_config(entities, nested_map)

          required_preloads =
            AshFormBuilder.Infer.detect_required_preloads(
              Enum.filter(entities, &is_struct(&1, AshFormBuilder.Field)),
              resource,
              form.action
            )

          schema = build_schema(entities, nested_map, required_preloads)

          action_type =
            case Ash.Resource.Info.action(dsl_state, form.action) do
              %{type: type} -> type
              _ -> infer_action_type(form.action)
            end

          %{
            action: form.action,
            type: action_type,
            nested_config: nested_config,
            required_preloads: required_preloads,
            schema: schema
          }
        end)

      create_form_module(module_name, resource, action_specs)
    end

    {:ok, dsl_state}
  end

  defp derive_form_module(resource, forms) do
    explicit =
      forms
      |> Enum.map(& &1.module)
      |> Enum.find(&(not is_nil(&1)))

    explicit || Module.concat([resource, Form])
  end

  # ---------------------------------------------------------------------------
  # Build the keyword list passed as `forms:` to AshPhoenix.Form
  # ---------------------------------------------------------------------------

  defp build_nested_config(entities, nested_map) do
    entities
    |> Enum.filter(&is_struct(&1, AshFormBuilder.NestedForm))
    |> Enum.map(fn nested ->
      rel_name = nested.relationship || nested.name
      destination = Map.get(nested_map, nested.name)

      type = if nested.cardinality == :many, do: :list, else: :single

      config =
        [
          type: type,
          resource: destination,
          create_action: nested.create_action,
          update_action: nested.update_action
        ]
        |> Enum.reject(fn {_k, v} -> is_nil(v) end)

      {rel_name, config}
    end)
  end

  # ---------------------------------------------------------------------------
  # Build the schema (list of field maps) for Domain Code Interface
  # ---------------------------------------------------------------------------

  defp build_schema(entities, nested_map, required_preloads) do
    fields =
      entities
      |> Enum.filter(&is_struct(&1, AshFormBuilder.Field))
      |> Enum.map(fn field ->
        %{
          name: field.name,
          label: field.label || humanize(field.name),
          type: field.type,
          required: field.required,
          options: field.options,
          relationship: field.relationship,
          relationship_type: field.relationship_type,
          destination_resource: field.destination_resource,
          opts: field.opts
        }
      end)

    nested_forms =
      entities
      |> Enum.filter(&is_struct(&1, AshFormBuilder.NestedForm))
      |> Enum.map(fn nested ->
        rel_name = nested.relationship || nested.name
        destination = Map.get(nested_map, nested.name)

        nested_fields =
          Enum.map(nested.fields, fn f ->
            %{
              name: f.name,
              label: f.label || humanize(f.name),
              type: f.type,
              required: f.required,
              options: f.options
            }
          end)

        %{
          name: nested.name,
          relationship: rel_name,
          cardinality: nested.cardinality,
          destination_resource: destination,
          create_action: nested.create_action,
          update_action: nested.update_action,
          fields: nested_fields
        }
      end)

    %{
      fields: fields,
      nested_forms: nested_forms,
      required_preloads: required_preloads
    }
  end

  defp humanize(value) when is_atom(value) do
    value
    |> to_string()
    |> String.split("_")
    |> Enum.map_join(" ", &String.capitalize/1)
  end

  defp humanize(value), do: to_string(value)

  # Last-resort fallback when the DSL state can't yet resolve the action's
  # type (e.g. the action was declared via `defaults [:create]` and the
  # action structs aren't materialised at this transformer phase). Names
  # follow Ash's `defaults` conventions.
  defp infer_action_type(:create), do: :create
  defp infer_action_type(:read), do: :read
  defp infer_action_type(:update), do: :update
  defp infer_action_type(:destroy), do: :destroy
  defp infer_action_type(_), do: nil

  # ---------------------------------------------------------------------------
  # Module creation
  # ---------------------------------------------------------------------------

  defp create_form_module(module, resource, action_specs) do
    actions_list = Enum.map(action_specs, & &1.action)
    actions_escaped = Macro.escape(actions_list)

    nested_config_by_action =
      Enum.reduce(action_specs, %{}, fn s, acc -> Map.put(acc, s.action, s.nested_config) end)

    schema_by_action =
      Enum.reduce(action_specs, %{}, fn s, acc -> Map.put(acc, s.action, s.schema) end)

    preloads_by_action =
      Enum.reduce(action_specs, %{}, fn s, acc ->
        Map.put(acc, s.action, s.required_preloads)
      end)

    nested_escaped = Macro.escape(nested_config_by_action)
    schema_escaped = Macro.escape(schema_by_action)
    preloads_escaped = Macro.escape(preloads_by_action)

    per_action_clauses =
      Enum.flat_map(action_specs, &per_action_helper_quoted(&1.action, &1.type))

    contents =
      quote do
        @moduledoc """
        Auto-generated form helpers for `#{inspect(unquote(resource))}`.

        One `for_<action>` helper is generated per declared form. Each
        function returns a `Phoenix.HTML.Form` ready to assign to a
        LiveView socket.
        """

        @resource unquote(resource)
        @form_actions unquote(actions_escaped)
        @nested_by_action unquote(nested_escaped)
        @schema_by_action unquote(schema_escaped)
        @preloads_by_action unquote(preloads_escaped)

        @doc "The Ash resource this module is bound to."
        def resource, do: @resource

        @doc "List of declared form actions."
        def actions, do: @form_actions

        @doc "Nested-form config for the given action."
        def nested_forms(action), do: Map.fetch!(@nested_by_action, action)

        @doc "Inferred schema for the given action."
        def schema(action), do: Map.fetch!(@schema_by_action, action)

        @doc "Relationships to preload before editing for the given action."
        def required_preloads(action), do: Map.get(@preloads_by_action, action, [])

        @doc """
        Build a form for any declared action. Update / destroy actions
        require `:record` in `opts`.
        """
        def for_action(action, opts \\ []) do
          opts = Keyword.put_new(opts, :forms, nested_forms(action))
          action_type = Ash.Resource.Info.action(@resource, action).type

          ash_form =
            case action_type do
              :create ->
                AshPhoenix.Form.for_create(@resource, action, opts)

              :update ->
                {record, opts} = Keyword.pop!(opts, :record)
                record = maybe_preload(record, action, opts)
                AshPhoenix.Form.for_update(record, action, opts)

              :destroy ->
                {record, opts} = Keyword.pop!(opts, :record)
                AshPhoenix.Form.for_destroy(record, action, opts)

              :read ->
                AshPhoenix.Form.for_read(@resource, action, opts)
            end

          Phoenix.Component.to_form(ash_form)
        end

        defp maybe_preload(record, action, opts) do
          case required_preloads(action) do
            [] -> record
            preloads -> Ash.load!(record, preloads, opts)
          end
        end

        unquote_splicing(per_action_clauses)
      end

    Module.create(module, contents, Macro.Env.location(__ENV__))
  end

  # One `for_<action>/N` helper is generated per declared form, regardless
  # of whether the action uses a standard name (`:create`, `:update`) or a
  # custom one (`:archive`, `:publish`, `:complete`). The arity depends on
  # the action's type — record-shaped actions (`:update`, `:destroy`) take
  # the record as the first argument, while resource-shaped actions
  # (`:create`, `:read`) only take options.
  defp per_action_helper_quoted(action, type) when type in [:create, :read] do
    fun_name = :"for_#{action}"

    [
      quote do
        @doc unquote("Build a form for the `:#{action}` (#{type}) action.")
        def unquote(fun_name)(opts \\ []), do: for_action(unquote(action), opts)
      end
    ]
  end

  defp per_action_helper_quoted(action, type) when type in [:update, :destroy] do
    fun_name = :"for_#{action}"

    [
      quote do
        @doc unquote(
               "Build a form for the `:#{action}` (#{type}) action. Pass the existing record as the first argument."
             )
        def unquote(fun_name)(record, opts \\ []) do
          for_action(unquote(action), Keyword.put(opts, :record, record))
        end
      end
    ]
  end

  # Action exists in DSL but type couldn't be resolved at compile time —
  # skip the shortcut. Callers can still use `for_action/2`.
  defp per_action_helper_quoted(_action, _type), do: []
end
