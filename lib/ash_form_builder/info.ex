defmodule AshFormBuilder.Info do
  @moduledoc """
  Introspection helpers for `AshFormBuilder` DSL data.

  As of v0.4 the DSL supports one form declaration per Ash action. All
  accessors take the action atom so callers can pick the right form
  config.

  Works on both compiled resource modules and in-progress `dsl_state`
  maps (the latter is used inside Spark transformers).

  ## Auto-inference

  `effective_fields/2` and `effective_entities/2` are the preferred
  runtime accessors. They merge auto-inferred fields (derived from the
  action's `accept` list via `AshFormBuilder.Infer`) with any explicit
  DSL overrides. Explicit declarations win on a per-field basis.

  The lower-level `form_fields/2` and `form_entities/2` return only the
  explicitly declared DSL entities.
  """

  alias Spark.Dsl.Extension

  @doc "All declared form configs in the order written."
  @spec forms(module() | map()) :: [AshFormBuilder.FormConfig.t()]
  def forms(resource_or_dsl) do
    Extension.get_entities(resource_or_dsl, [:forms])
  end

  @doc "Fetch the `FormConfig` for the given action, or `nil`."
  @spec form_config(module() | map(), atom()) :: AshFormBuilder.FormConfig.t() | nil
  def form_config(resource_or_dsl, action) do
    Enum.find(forms(resource_or_dsl), &(&1.action == action))
  end

  @doc "All DSL entities (fields + nested forms) for the given action."
  def form_entities(resource_or_dsl, action) do
    case form_config(resource_or_dsl, action) do
      nil -> []
      config -> config.entities
    end
  end

  @doc "Only the top-level `Field` structs declared for the given action."
  def form_fields(resource_or_dsl, action) do
    resource_or_dsl
    |> form_entities(action)
    |> Enum.filter(&is_struct(&1, AshFormBuilder.Field))
  end

  @doc "Only the `NestedForm` structs declared for the given action."
  def form_nested(resource_or_dsl, action) do
    resource_or_dsl
    |> form_entities(action)
    |> Enum.filter(&is_struct(&1, AshFormBuilder.NestedForm))
  end

  @doc "Submit label for the given action's form, defaults to `\"Submit\"`."
  def form_submit_label(resource_or_dsl, action) do
    case form_config(resource_or_dsl, action) do
      nil -> "Submit"
      config -> config.submit_label
    end
  end

  @doc "Wrapper CSS class for the given action's form."
  def form_wrapper_class(resource_or_dsl, action) do
    case form_config(resource_or_dsl, action) do
      nil -> "space-y-4"
      config -> config.wrapper_class
    end
  end

  @doc "HTML id for the given action's form, or `nil`."
  def form_html_id(resource_or_dsl, action) do
    case form_config(resource_or_dsl, action) do
      nil -> nil
      config -> config.form_id
    end
  end

  @doc "Override module name for the generated form helper, or `nil`."
  def form_module_override(resource_or_dsl, action) do
    case form_config(resource_or_dsl, action) do
      nil -> nil
      config -> config.module
    end
  end

  @doc "True when the resource declares a form for the given action."
  def has_form?(resource_or_dsl, action) do
    not is_nil(form_config(resource_or_dsl, action))
  end

  @doc """
  Theme module for the action's form.

  Resolves in this order:

  1. The form's `theme:` DSL value (atom or module — looked up in
     `AshFormBuilder.Themes`).
  2. The `:theme` Application env (atom or module — same lookup).
  3. `AshFormBuilder.Themes.Default`.
  """
  def form_theme(resource_or_dsl, action) do
    case form_config(resource_or_dsl, action) do
      %{theme: ref} when not is_nil(ref) ->
        AshFormBuilder.Themes.resolve(ref)

      _ ->
        case Application.get_env(:ash_form_builder, :theme) do
          nil -> AshFormBuilder.Themes.Default
          ref -> AshFormBuilder.Themes.resolve(ref)
        end
    end
  end

  @doc "Accent color atom for the action's form (default `:indigo`)."
  def form_accent(resource_or_dsl, action) do
    case form_config(resource_or_dsl, action) do
      %{accent: a} when not is_nil(a) -> a
      _ -> :indigo
    end
  end

  @doc "Transition intensity for the action's form (`:none | :subtle | :smooth`)."
  def form_transitions(resource_or_dsl, action) do
    case form_config(resource_or_dsl, action) do
      %{transitions: t} when not is_nil(t) -> t
      _ -> :subtle
    end
  end

  @doc "List of fields/nested-form names to suppress, declared via `ignore_fields` on the form."
  def form_ignore_fields(resource_or_dsl, action) do
    case form_config(resource_or_dsl, action) do
      %{ignore_fields: list} when is_list(list) -> list
      _ -> []
    end
  end

  # ---------------------------------------------------------------------------
  # Auto-inference (runtime only — requires compiled Ash.Resource.Info)
  # ---------------------------------------------------------------------------

  @doc """
  Returns the effective list of `Field` structs for the given action.

  Fields are produced by auto-inferring from the action's `accept` list
  (falling back to writable attributes when `accept` is empty), then
  applying explicit DSL declarations as overrides.

  Any DSL field whose name is not in the inferred list is appended at
  the end, allowing argument fields not in `accept`.
  """
  @spec effective_fields(module(), atom()) :: [AshFormBuilder.Field.t()]
  def effective_fields(resource, action) do
    explicit_fields = form_fields(resource, action)
    explicit_map = Map.new(explicit_fields, &{&1.name, &1})

    nested_names =
      resource
      |> form_nested(action)
      |> MapSet.new(& &1.name)

    inferred =
      resource
      |> AshFormBuilder.Infer.infer_fields(action)
      |> Enum.reject(&MapSet.member?(nested_names, &1.name))

    merged =
      Enum.map(inferred, fn inferred_field ->
        case Map.get(explicit_map, inferred_field.name) do
          nil -> inferred_field
          explicit -> merge_field(inferred_field, explicit)
        end
      end)

    merged_names = MapSet.new(merged, & &1.name)

    extras =
      Enum.reject(explicit_fields, &MapSet.member?(merged_names, &1.name))

    merged ++ extras
  end

  # Per-field merge: take every non-default value from the explicit DSL
  # declaration, but inherit anything the user did *not* set from the
  # inferred field. This is what lets `field :status do type :select end`
  # keep its auto-inferred enum options instead of erasing them.
  defp merge_field(%AshFormBuilder.Field{} = inferred, %AshFormBuilder.Field{} = explicit) do
    inferred
    |> Map.from_struct()
    |> Enum.reduce(explicit, fn {key, inferred_value}, acc ->
      explicit_value = Map.get(acc, key)

      if explicit_field_set?(key, explicit_value) do
        acc
      else
        Map.put(acc, key, inferred_value)
      end
    end)
  end

  # The Field struct's defaults — anything matching these means the user
  # did not explicitly set the option, so the inferred value should win.
  defp explicit_field_set?(:type, :text_input), do: false
  defp explicit_field_set?(:required, false), do: false
  defp explicit_field_set?(:autofocus, false), do: false
  defp explicit_field_set?(:readonly, false), do: false
  defp explicit_field_set?(:disabled, false), do: false
  defp explicit_field_set?(:options, []), do: false
  defp explicit_field_set?(:opts, []), do: false
  defp explicit_field_set?(_key, nil), do: false
  defp explicit_field_set?(_key, _value), do: true

  @doc """
  Returns all effective form entities: `effective_fields/2` followed by
  the `NestedForm` structs declared for the action.

  For zero-config use, a bare `nested :foo do end` block (no `field`
  children) auto-inflates with fields inferred from the destination
  resource's create action — so users get a fully wired sub-form for
  has_many relationships without writing any field declarations.
  """
  @spec effective_entities(module(), atom()) :: list()
  def effective_entities(resource, action) do
    declared_nested = form_nested(resource, action)
    declared_names = MapSet.new(declared_nested, & &1.name)
    ignored = MapSet.new(form_ignore_fields(resource, action) || [])

    auto_nested =
      resource
      |> auto_inferred_nested(action)
      |> Enum.reject(&MapSet.member?(declared_names, &1.name))
      |> Enum.reject(&MapSet.member?(ignored, &1.name))

    nested =
      (declared_nested ++ auto_nested)
      |> Enum.map(&hydrate_nested(&1, resource))

    effective_fields(resource, action) ++ nested
  end

  # Build NestedForm structs for has_many relationships that the action
  # exposes via `change manage_relationship(:foo, type: :create)`. Lets a
  # zero-config `forms do form :create do end end` produce a usable
  # sub-form without any nested DSL declaration.
  defp auto_inferred_nested(resource, action_name) do
    action = Ash.Resource.Info.action(resource, action_name)

    if is_nil(action) do
      []
    else
      action
      |> manage_relationship_specs_for_nesting()
      |> Enum.flat_map(fn spec ->
        case Ash.Resource.Info.relationship(resource, spec.relationship) do
          %{type: :has_many, name: rel_name, destination: dest} ->
            [
              %AshFormBuilder.NestedForm{
                name: spec.argument || rel_name,
                relationship: rel_name,
                destination_resource: dest,
                cardinality: :many,
                add_label: "Add",
                remove_label: "Remove",
                create_action: :create,
                update_action: :update,
                fields: []
              }
            ]

          _ ->
            []
        end
      end)
    end
  end

  defp manage_relationship_specs_for_nesting(action) do
    changes =
      case action do
        %{changes: c} when is_list(c) -> c
        _ -> []
      end

    Enum.flat_map(changes, fn
      %Ash.Resource.Change{change: {Ash.Resource.Change.ManageRelationship, opts}}
      when is_list(opts) ->
        rel = Keyword.get(opts, :relationship)
        arg = Keyword.get(opts, :argument, rel)
        if is_atom(rel), do: [%{relationship: rel, argument: arg}], else: []

      _ ->
        []
    end)
  end

  defp hydrate_nested(%AshFormBuilder.NestedForm{fields: fields} = nested, resource)
       when is_list(fields) do
    case fields do
      [] ->
        case nested_destination(nested, resource) do
          nil ->
            nested

          destination ->
            inferred =
              AshFormBuilder.Infer.infer_fields(destination, nested.create_action || :create)

            %{nested | fields: inferred}
        end

      _ ->
        nested
    end
  end

  defp hydrate_nested(nested, _resource), do: nested

  defp nested_destination(%AshFormBuilder.NestedForm{} = nested, resource) do
    nested.destination_resource ||
      case Ash.Resource.Info.relationship(resource, nested.relationship || nested.name) do
        nil -> nil
        rel -> rel.destination
      end
  end

  # ---------------------------------------------------------------------------
  # AshPhoenix nested form config
  # ---------------------------------------------------------------------------

  @doc """
  Builds the AshPhoenix.Form `:forms` keyword list for the given action.
  """
  def build_nested_forms_config(resource_or_dsl, action) do
    nested_resource_map =
      Extension.get_persisted(resource_or_dsl, :ash_form_builder_nested_resources) ||
        %{}

    resource_or_dsl
    |> form_nested(action)
    |> Enum.map(fn nested ->
      rel_name = nested.relationship || nested.name
      destination = Map.get(nested_resource_map, nested.name)
      type = if nested.cardinality == :many, do: :list, else: :single

      config = [
        type: type,
        resource: destination,
        create_action: nested.create_action,
        update_action: nested.update_action
      ]

      {rel_name, config}
    end)
  end
end
