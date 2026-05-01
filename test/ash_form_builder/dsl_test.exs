defmodule AshFormBuilder.DslTest do
  use ExUnit.Case, async: true

  alias AshFormBuilder.Field
  alias AshFormBuilder.Info
  alias AshFormBuilder.NestedForm
  alias AshFormBuilder.Test.DslSampleResource

  setup do
    # Ensure the DslSampleResource module is fully loaded
    Code.ensure_loaded?(DslSampleResource)
    Code.ensure_loaded?(DslSampleResource.Form)
    :ok
  end

  describe "DSL entities" do
    test "form block is parsed" do
      assert [config] = Info.forms(DslSampleResource)
      assert config.action == :create
      assert Info.form_submit_label(DslSampleResource, :create) == "Create Post"
      assert Info.form_wrapper_class(DslSampleResource, :create) == "space-y-4"
    end

    test "field entities are parsed" do
      fields = Info.form_fields(DslSampleResource, :create)

      title_field = Enum.find(fields, &(&1.name == :title))
      assert title_field.label == "Post Title"
      assert title_field.placeholder == "Enter title"
      assert title_field.required == true

      body_field = Enum.find(fields, &(&1.name == :body))
      assert body_field.type == :textarea
    end
  end

  describe "Generated Form Module" do
    test "Form module is generated" do
      assert function_exported?(DslSampleResource.Form, :for_create, 1)
      assert function_exported?(DslSampleResource.Form, :schema, 1)
      assert function_exported?(DslSampleResource.Form, :nested_forms, 1)
      assert function_exported?(DslSampleResource.Form, :actions, 0)
    end

    test "schema/1 returns expected structure" do
      schema = DslSampleResource.Form.schema(:create)

      assert is_map(schema)
      assert is_list(schema.fields)
      assert is_list(schema.nested_forms)
      assert is_list(schema.required_preloads)
    end
  end

  describe "NestedForm struct" do
    test "NestedForm defaults are applied" do
      nested = %NestedForm{name: :tags, fields: [%Field{name: :name}]}
      assert nested.cardinality == :many
      assert nested.add_label == "Add"
      assert nested.remove_label == "Remove"
    end
  end

  describe "effective_fields/2 — per-field merging" do
    alias AshFormBuilder.Test.Resources.Article

    test "explicit DSL field declarations inherit auto-inferred values for unset keys" do
      # `Article` declares `form :create do end` with NO field overrides,
      # so every field is purely inferred — including the `:status` enum
      # whose `options` are derived from the `one_of` constraint.
      fields = Info.effective_fields(Article, :create)
      status = Enum.find(fields, &(&1.name == :status))

      assert status.type == :select
      assert length(status.options) == 3
    end

    test "explicit DSL declarations override only what they set, keeping inferred extras" do
      alias AshFormBuilder.Test.Resources.Review

      # `Review` declares an explicit `field :body` with type/label/hint
      # but NO inferred-only attributes (required, etc.). The merged
      # field should keep both the DSL overrides and any inferred values.
      fields = Info.effective_fields(Review, :create)
      body = Enum.find(fields, &(&1.name == :body))

      # DSL-set values
      assert body.type == :textarea
      assert body.label == "Full Review"
      assert body.hint == "Be as detailed as possible"
    end
  end

  describe "Field struct — additional component options" do
    test "new HTML-attribute keys default to nil/false" do
      field = %Field{name: :title}

      assert field.autofocus == false
      assert field.readonly == false
      assert field.disabled == false
      assert is_nil(field.autocomplete)
      assert is_nil(field.min)
      assert is_nil(field.max)
      assert is_nil(field.step)
      assert is_nil(field.rows)
      assert is_nil(field.prefix)
      assert is_nil(field.suffix)
    end
  end
end
