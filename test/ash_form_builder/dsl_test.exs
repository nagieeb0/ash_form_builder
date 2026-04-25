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
      assert Info.form_action(DslSampleResource) == :create
      assert Info.form_submit_label(DslSampleResource) == "Create Post"
      assert Info.form_wrapper_class(DslSampleResource) == "space-y-4"
    end

    test "field entities are parsed" do
      fields = Info.form_fields(DslSampleResource)

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
      assert function_exported?(DslSampleResource.Form, :for_update, 2)
      assert function_exported?(DslSampleResource.Form, :schema, 0)
      assert function_exported?(DslSampleResource.Form, :nested_forms, 0)
    end

    test "schema/0 returns expected structure" do
      schema = DslSampleResource.Form.schema()

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
end
