defmodule AshFormBuilder.InferTest do
  use ExUnit.Case, async: true

  alias AshFormBuilder.Infer
  alias AshFormBuilder.Test.Domain.Clinic
  alias AshFormBuilder.Test.Domain.Specialty
  alias AshFormBuilder.Test.Domain.Subtask

  describe "infer_fields/3 — attribute and argument mapping" do
    test "maps Ash types to UI types for Clinic :create" do
      fields = Infer.infer_fields(Clinic, :create)

      assert field(fields, :name).type == :text_input
      assert field(fields, :name).required == true

      assert field(fields, :phone).type == :text_input
      assert field(fields, :phone).required == false
    end

    test "maps many_to_many relationships to :multiselect_combobox" do
      fields = Infer.infer_fields(Clinic, :create)

      specialties = field(fields, :specialties)
      assert specialties.type == :multiselect_combobox
      assert specialties.relationship == :specialties
      assert specialties.relationship_type == :many_to_many
      assert specialties.destination_resource == Specialty
      assert Keyword.get(specialties.opts, :label_key) == :name
      assert Keyword.get(specialties.opts, :value_key) == :id
    end

    test "has_many relationships are omitted from inferred fields" do
      fields = Infer.infer_fields(Clinic, :create)
      refute Enum.any?(fields, &(&1.name == :subtasks))
    end

    test "maps belongs_to relationships to :select for Subtask" do
      fields = Infer.infer_fields(Subtask, :create)

      clinic = field(fields, :clinic)
      assert clinic.type == :select
      assert clinic.relationship == :clinic
      assert clinic.relationship_type == :belongs_to
      assert clinic.destination_resource == Clinic
    end

    test "includes action arguments after accept fields" do
      fields = Infer.infer_fields(Clinic, :create)

      assert field(fields, :referral_code).type == :text_input
      assert field(fields, :referral_code).required == false
    end

    test "returns an empty list for unknown actions" do
      assert Infer.infer_fields(Clinic, :not_an_action) == []
    end

    test "respects ignore_fields" do
      fields = Infer.infer_fields(Clinic, :create, ignore_fields: [:phone])
      refute Enum.any?(fields, &(&1.name == :phone))
    end

    test "allows overriding many_to_many UI type" do
      fields = Infer.infer_fields(Clinic, :create, many_to_many_as: :select)
      assert field(fields, :specialties).type == :select
    end
  end

  describe "infer_schema/3" do
    test "returns fields, nested_forms, action, resource, and required_preloads" do
      schema = Infer.infer_schema(Clinic, :create)

      assert schema.action == :create
      assert schema.resource == Clinic
      assert is_list(schema.fields)
      assert is_list(schema.nested_forms)
      assert schema.required_preloads == []
    end

    test "detects required preloads for update actions with many_to_many combobox fields" do
      schema = Infer.infer_schema(Clinic, :update)
      assert :specialties in schema.required_preloads
    end

    test "builds nested form config for belongs_to select fields" do
      schema = Infer.infer_schema(Subtask, :create)

      assert Keyword.has_key?(schema.nested_forms, :clinic)

      assert {:clinic, config} = List.keyfind(schema.nested_forms, :clinic, 0)
      assert config[:type] == :single
      assert config[:resource] == Clinic
      assert config[:create_action] == :create
      assert config[:update_action] == :update
    end
  end

  describe "detect_required_preloads/3" do
    test "returns [] for non-update actions" do
      fields = Infer.infer_fields(Clinic, :create)
      assert Infer.detect_required_preloads(fields, Clinic, :create) == []
    end

    test "returns many_to_many relationship names for update actions" do
      fields = Infer.infer_fields(Clinic, :update)
      preloads = Infer.detect_required_preloads(fields, Clinic, :update)
      assert :specialties in preloads
    end
  end

  describe "detect_field_type/2" do
    test "returns :attribute for attributes" do
      assert Infer.detect_field_type(Clinic, :name) == :attribute
    end

    test "returns {:relationship, rel} for relationships" do
      assert {:relationship, rel} = Infer.detect_field_type(Clinic, :specialties)
      assert rel.name == :specialties
    end
  end

  defp field(fields, name), do: Enum.find(fields, &(&1.name == name))
end
