defmodule AshFormBuilder.Transformers.GenerateFormModule do
  @moduledoc """
  Generates a `Resource.Form` helper module at compile time for every resource
  that declares a `form` block.

  The generated module provides:

    * `for_action/2`   — creates an AshPhoenix.Form for the declared action,
                         pre-configured with all nested form definitions.
    * `for_create/1`   — alias when the declared action is a create action.
    * `for_update/2`   — alias when the declared action is an update action;
                         first arg is the existing record.
    * `schema/0`       — returns the inferred form schema as a list of field maps.
    * `nested_forms/0` — returns the AshPhoenix.Form `:forms` configuration.

  ## Domain Code Interface Integration

  When used with Domain Code Interfaces, the form helpers work seamlessly:

      # Domain automatically generates form_to_<action> functions
      defmodule MyApp.Billing do
        use Ash.Domain

        resources do
          resource MyApp.Billing.Clinic do
            define :form_to_create_clinic, action: :create
            define :form_to_update_clinic, action: :update
          end
        end
      end

      # In your LiveView:
      form = MyApp.Billing.Clinic.Form.for_create(actor: socket.assigns.current_user)

  ## Example

      # Create form in a LiveView mount:
      form = MyApp.Post.Form.for_create(actor: current_user)
      {:ok, assign(socket, form: form)}

      # Then in the template:
      <.live_component module={AshFormBuilder.FormComponent}
        id="create-post"
        form={@form} />
  """

  use Spark.Dsl.Transformer

  alias Spark.Dsl.Transformer

  @impl Spark.Dsl.Transformer
  def before?(_), do: false

  @impl Spark.Dsl.Transformer
  def after?(AshFormBuilder.Transformers.ResolveNestedResources), do: true
  def after?(_), do: false

  @impl Spark.Dsl.Transformer
  def transform(dsl_state) do
    resource = Transformer.get_persisted(dsl_state, :module)
    action = Spark.Dsl.Extension.get_opt(dsl_state, [:form], :action)

    if action do
      component_module =
        Spark.Dsl.Extension.get_opt(dsl_state, [:form], :module) ||
          Module.concat([resource, Form])

      nested_map =
        Transformer.get_persisted(dsl_state, :ash_form_builder_nested_resources) || %{}

      entities = Spark.Dsl.Extension.get_entities(dsl_state, [:form])

      # Build nested config for AshPhoenix.Form
      nested_config = build_nested_config(entities, nested_map)

      # Calculate required preloads for update actions
      # This ensures many_to_many relationships are loaded when editing
      required_preloads =
        AshFormBuilder.Infer.detect_required_preloads(
          AshFormBuilder.Info.form_fields(dsl_state),
          resource,
          action
        )

      # Build schema from DSL entities (used by Domain Code Interfaces)
      schema = build_schema(entities, nested_map, required_preloads)

      create_form_module(
        component_module,
        resource,
        action,
        nested_config,
        schema,
        required_preloads
      )
    end

    {:ok, dsl_state}
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
  # Build the schema (list of field maps) for Domain Code Interface integration
  # ---------------------------------------------------------------------------

  defp build_schema(entities, nested_map, required_preloads) do
    # Top-level fields
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

    # Nested form configurations
    nested_forms =
      entities
      |> Enum.filter(&is_struct(&1, AshFormBuilder.NestedForm))
      |> Enum.map(fn nested ->
        rel_name = nested.relationship || nested.name
        destination = Map.get(nested_map, nested.name)

        nested_fields =
          nested.fields
          |> Enum.map(fn f ->
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

  # ---------------------------------------------------------------------------
  # Module creation
  # ---------------------------------------------------------------------------

  defp create_form_module(module, resource, action, nested_config, schema, required_preloads) do
    nested_config_escaped = Macro.escape(nested_config)
    schema_escaped = Macro.escape(schema)
    required_preloads_escaped = Macro.escape(required_preloads)

    contents =
      quote do
        @moduledoc """
        Auto-generated form helper for `#{inspect(unquote(resource))}`.

        ## Creating a form

            form = #{inspect(__MODULE__)}.for_create(actor: current_user)
            {:ok, assign(socket, form: form)}

        ## Updating a record

            # For update actions, required relationships are automatically preloaded
            form = #{inspect(__MODULE__)}.for_update(record, actor: current_user)
            {:ok, assign(socket, form: form)}

        ## Domain Code Interface Integration

        When using Ash Domain Code Interfaces, this helper works with the
        automatically generated `form_to_<action>` functions:

            # Domain configuration:
            define :form_to_create_clinic, action: :create

            # LiveView usage:
            form = MyApp.Billing.Clinic.Form.for_create(actor: current_user)

        ## Schema Introspection

        Access the inferred form schema:

            MyApp.Clinic.Form.schema()
            # => %{fields: [...], nested_forms: [...], required_preloads: [...]}

        ## Rendering

            <.live_component
              module={AshFormBuilder.FormComponent}
              id="my-form"
              form={@form} />

        The component sends `{:form_submitted, resource, result}` to the parent
        LiveView on success.  Handle it in `handle_info/2`.

        ## Domain-Driven Validation Assurance

        Using the Domain Code Interface through `for_create/1` or `for_update/2`
        ensures that all Ash Framework features are fully respected:

        **Policy Enforcement:** All Ash policies defined on the resource are
        automatically checked. Unauthorized users receive policy violation errors.

        **Validations:** All server-side validations run on every form submission,
        including custom validations defined in `validations do...end` blocks.
        Errors are automatically rendered through the configured theme.

        **Atomic Updates:** Changes defined in `changes do...end` blocks execute
        atomically within the same transaction, ensuring data consistency.

        **Preparations:** Any `prepare` steps defined on the action run before
        form processing, allowing for data transformation or enrichment.

        The UI Adapter (Theme) receives standard Ash form errors via the
        `Phoenix.HTML.Form` struct's `:errors` field and renders them
        appropriately for the chosen UI framework (MishkaChelekom, etc.).
        """

        @resource unquote(resource)
        @form_action unquote(action)
        @nested_config unquote(nested_config_escaped)
        @schema unquote(schema_escaped)
        @required_preloads unquote(required_preloads_escaped)

        @doc "The Ash resource this form is bound to."
        def resource, do: @resource

        @doc "The action this form targets."
        def action, do: @form_action

        @doc """
        AshPhoenix.Form `:forms` config for nested relationships.

        Prefer `nested_forms/0` for consistency with Ash Domain Code Interfaces.
        """
        @deprecated "Use nested_forms/0 instead for consistency with Domain Code Interfaces"
        def nested_config, do: @nested_config

        @doc """
        Returns the nested forms configuration as a keyword list.
        Compatible with AshPhoenix.Form's `:forms` option.
        """
        def nested_forms, do: @nested_config

        @doc """
        Returns the inferred form schema.

        ## Schema Structure

            %{
              fields: [
                %{
                  name: :field_name,
                  label: "Field Label",
                  type: :text_input,
                  required: true,
                  options: [],
                  relationship: nil,
                  relationship_type: nil,
                  destination_resource: nil,
                  opts: []
                }
              ],
              nested_forms: [
                %{
                  name: :nested_name,
                  relationship: :relationship_name,
                  cardinality: :many,
                  destination_resource: RelatedResource,
                  create_action: :create,
                  update_action: :update,
                  fields: [...]
                }
              ],
              required_preloads: [:relation_name, ...]
            }
        """
        def schema, do: @schema

        @doc """
        Returns the list of relationships that must be preloaded for update forms.

        This ensures many_to_many relationships are loaded when editing records,
        so the form can display existing associations.
        """
        def required_preloads, do: @required_preloads

        @doc """
        Creates an `AshPhoenix.Form` (already wrapped with `to_form/1`) for
        the declared action.  Pass `actor:` and any other AshPhoenix options.

            form = #{inspect(__MODULE__)}.for_action(:create, actor: current_user)
        """
        def for_action(action_name, opts \\ []) do
          opts = Keyword.put_new(opts, :forms, @nested_config)
          action_type = Ash.Resource.Info.action(@resource, action_name).type

          ash_form =
            case action_type do
              :create ->
                AshPhoenix.Form.for_create(@resource, action_name, opts)

              :update ->
                record = Keyword.fetch!(opts, :record)
                opts = Keyword.delete(opts, :record)
                AshPhoenix.Form.for_update(record, action_name, opts)

              :destroy ->
                record = Keyword.fetch!(opts, :record)
                opts = Keyword.delete(opts, :record)
                AshPhoenix.Form.for_destroy(record, action_name, opts)

              :read ->
                AshPhoenix.Form.for_read(@resource, action_name, opts)
            end

          Phoenix.Component.to_form(ash_form)
        end

        @doc """
        Creates an `AshPhoenix.Form` using the Domain Code Interface pattern.

        This is a convenience wrapper that works with the Domain's auto-generated
        `form_to_<action>` functions. It ensures all Ash validations, atomics,
        and policies are fully respected.

        ## Example

            # With Domain Code Interface:
            form = MyApp.Billing.form_to_create_clinic(%{}, actor: current_user)

            # With this helper:
            form = MyApp.Billing.Clinic.Form.for_domain_action(:create, actor: current_user)
        """
        def for_domain_action(action_name \\ @form_action, opts \\ []) do
          # The Domain Code Interface automatically handles:
          # - Policy enforcement
          # - Preparations and changes
          # - Atomic updates
          # - Validation rules
          for_action(action_name, opts)
        end

        @doc "Convenience wrapper around `for_action/2` for create actions."
        def for_create(opts \\ []) do
          for_action(@form_action, opts)
        end

        @doc """
        Convenience wrapper around `for_action/2` for update actions.
        Pass the existing record as the first argument.

        Automatically preloads required relationships (e.g., many_to_many) to ensure
        the form displays existing associations correctly.
        """
        def for_update(record, opts \\ []) do
          # Automatically preload required relationships for update forms
          record =
            if Enum.empty?(@required_preloads) do
              record
            else
              Ash.load!(record, @required_preloads, opts)
            end

          for_action(@form_action, Keyword.put(opts, :record, record))
        end
      end

    Module.create(module, contents, Macro.Env.location(__ENV__))
  end
end
