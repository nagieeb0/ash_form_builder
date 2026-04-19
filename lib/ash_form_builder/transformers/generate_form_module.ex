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

      nested_config = build_nested_config(entities, nested_map)

      create_form_module(component_module, resource, action, nested_config)
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
  # Module creation
  # ---------------------------------------------------------------------------

  defp create_form_module(module, resource, action, nested_config) do
    nested_config_escaped = Macro.escape(nested_config)

    contents =
      quote do
        @moduledoc """
        Auto-generated form helper for `#{inspect(unquote(resource))}`.

        ## Creating a form

            form = #{inspect(__MODULE__)}.for_create(actor: current_user)
            {:ok, assign(socket, form: form)}

        ## Updating a record

            form = #{inspect(__MODULE__)}.for_update(record, actor: current_user)
            {:ok, assign(socket, form: form)}

        ## Rendering

            <.live_component
              module={AshFormBuilder.FormComponent}
              id="my-form"
              form={@form} />

        The component sends `{:form_submitted, resource, result}` to the parent
        LiveView on success.  Handle it in `handle_info/2`.
        """

        @resource unquote(resource)
        @form_action unquote(action)
        @nested_config unquote(nested_config_escaped)

        @doc "The Ash resource this form is bound to."
        def resource, do: @resource

        @doc "The action this form targets."
        def action, do: @form_action

        @doc "AshPhoenix.Form `:forms` config for nested relationships."
        def nested_config, do: @nested_config

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

        @doc "Convenience wrapper around `for_action/2` for create actions."
        def for_create(opts \\ []) do
          for_action(@form_action, opts)
        end

        @doc """
        Convenience wrapper around `for_action/2` for update actions.
        Pass the existing record as the first argument.
        """
        def for_update(record, opts \\ []) do
          for_action(@form_action, Keyword.put(opts, :record, record))
        end
      end

    Module.create(module, contents, Macro.Env.location(__ENV__))
  end
end
