defmodule AshFormBuilder.Info do
  @moduledoc """
  Introspection helpers for `AshFormBuilder` DSL data.

  Works on both compiled resource modules and in-progress `dsl_state` maps
  (the latter is used inside Spark transformers).

  ## Auto-inference

  `effective_fields/1` and `effective_entities/1` are the preferred runtime
  accessors. They merge auto-inferred fields (derived from the action's
  `accept` list via `AshFormBuilder.TypeInference`) with any explicit DSL
  overrides. Explicit declarations win on a per-field basis.

  The lower-level `form_fields/1` and `form_entities/1` return only the
  explicitly declared DSL entities — useful inside transformers where
  `Ash.Resource.Info` is not yet available.
  """

  use Spark.InfoGenerator,
    extension: AshFormBuilder,
    sections: [:form]

  @doc "All DSL entities in declaration order (mix of `Field` and `NestedForm` structs)."
  def form_entities(resource_or_dsl) do
    Spark.Dsl.Extension.get_entities(resource_or_dsl, [:form])
  end

  @doc "Only the top-level `Field` structs declared in the DSL."
  def form_fields(resource_or_dsl) do
    resource_or_dsl
    |> form_entities()
    |> Enum.filter(&is_struct(&1, AshFormBuilder.Field))
  end

  @doc "Only the `NestedForm` structs declared in the DSL."
  def form_nested(resource_or_dsl) do
    resource_or_dsl
    |> form_entities()
    |> Enum.filter(&is_struct(&1, AshFormBuilder.NestedForm))
  end

  @doc "Returns the configured `:action` option, or `nil` if no `form` block."
  def form_action(resource_or_dsl) do
    Spark.Dsl.Extension.get_opt(resource_or_dsl, [:form], :action)
  end

  @doc "Returns the configured `:submit_label`, defaulting to `\"Submit\"`."
  def form_submit_label(resource_or_dsl) do
    Spark.Dsl.Extension.get_opt(resource_or_dsl, [:form], :submit_label) || "Submit"
  end

  @doc "Returns the configured `:wrapper_class`, defaulting to `\"space-y-4\"`."
  def form_wrapper_class(resource_or_dsl) do
    Spark.Dsl.Extension.get_opt(resource_or_dsl, [:form], :wrapper_class) || "space-y-4"
  end

  @doc "Returns the configured `:form_id`, or `nil`."
  def form_html_id(resource_or_dsl) do
    Spark.Dsl.Extension.get_opt(resource_or_dsl, [:form], :form_id)
  end

  @doc "Returns the override `:module` option, or `nil` (generator uses `Resource.Form` by default)."
  def form_module_override(resource_or_dsl) do
    Spark.Dsl.Extension.get_opt(resource_or_dsl, [:form], :module)
  end

  @doc "True when the resource has a `form` block with an `action` set."
  def has_form?(resource_or_dsl) do
    form_action(resource_or_dsl) != nil
  end

  # ---------------------------------------------------------------------------
  # Auto-inference (runtime only — requires compiled Ash.Resource.Info)
  # ---------------------------------------------------------------------------

  @doc """
  Returns the effective list of `Field` structs for the form action.

  Fields are produced by auto-inferring from the action's `accept` list, then
  applying explicit DSL declarations as overrides (explicit wins per field name).

  Any DSL field whose name is not in the inferred list is appended at the end,
  allowing you to add argument fields not in `accept`.

  Only call this on a compiled resource module, not on a `dsl_state` map.
  """
  @spec effective_fields(module()) :: [AshFormBuilder.Field.t()]
  def effective_fields(resource) do
    action = form_action(resource)

    if is_nil(action) do
      []
    else
      explicit_fields = form_fields(resource)
      explicit_map = Map.new(explicit_fields, &{&1.name, &1})

      inferred = AshFormBuilder.TypeInference.infer_fields(resource, action)

      merged =
        Enum.map(inferred, fn inferred_field ->
          Map.get(explicit_map, inferred_field.name, inferred_field)
        end)

      merged_names = MapSet.new(merged, & &1.name)

      extras =
        Enum.reject(explicit_fields, &MapSet.member?(merged_names, &1.name))

      merged ++ extras
    end
  end

  @doc """
  Returns all effective form entities: `effective_fields/1` followed by
  the `NestedForm` structs declared in the DSL.

  This is the preferred accessor for rendering — it gives a complete,
  ordered list of what to render without requiring explicit field declarations.

  Only call this on a compiled resource module.
  """
  @spec effective_entities(module()) :: list()
  def effective_entities(resource) do
    effective_fields(resource) ++ form_nested(resource)
  end

  # ---------------------------------------------------------------------------
  # AshPhoenix nested form config
  # ---------------------------------------------------------------------------

  @doc """
  Builds the AshPhoenix.Form `:forms` keyword list from the `nested` entities.

  Used by the generated `Resource.Form.for_action/2` helper so callers never
  have to hand-write the nested form configuration.
  """
  def build_nested_forms_config(resource_or_dsl) do
    nested_resource_map =
      Spark.Dsl.Extension.get_persisted(resource_or_dsl, :ash_form_builder_nested_resources) ||
        %{}

    resource_or_dsl
    |> form_nested()
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
