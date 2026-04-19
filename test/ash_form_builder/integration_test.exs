defmodule AshFormBuilder.IntegrationTest do
  use ExUnit.Case, async: true

  alias AshFormBuilder.{Infer, Info}
  alias AshFormBuilder.Test.Domain
  alias AshFormBuilder.Test.Domain.Clinic

  describe "Infer vs DSL merge" do
    test "Infer.infer_fields/3 uses Ash metadata only (no DSL labels)" do
      inferred_specialties =
        Infer.infer_fields(Clinic, :create) |> Enum.find(&(&1.name == :specialties))

      assert inferred_specialties.label == "Specialties"
    end

    test "Info.effective_fields/1 applies DSL overrides on top of inference" do
      effective_specialties =
        Info.effective_fields(Clinic) |> Enum.find(&(&1.name == :specialties))

      assert effective_specialties.label == "Specialties (DSL)"
      assert Keyword.get(effective_specialties.opts, :search_event) == "search_specialties"
      assert Keyword.get(effective_specialties.opts, :debounce) == 150
    end
  end

  describe "AshPhoenix.Form compatibility" do
    test "generated nested_forms/0 is accepted by AshPhoenix.Form.for_create/3" do
      forms = Clinic.Form.nested_forms()

      ash_form =
        AshPhoenix.Form.for_create(Clinic, :create,
          domain: Domain,
          authorize?: false,
          forms: forms
        )

      assert %AshPhoenix.Form{} = ash_form
    end

    test "Domain code interface form helpers exist" do
      assert function_exported?(Domain, :form_to_create_clinic, 2)
      assert function_exported?(Domain, :form_to_update_clinic, 2)
    end
  end

  describe "Generated Clinic.Form module" do
    test "exports nested_forms/0, schema/0, and required_preloads/0" do
      assert Clinic.Form.required_preloads() == []
      assert is_list(Clinic.Form.nested_forms())
      assert match?(%{fields: _, nested_forms: _, required_preloads: _}, Clinic.Form.schema())
    end
  end
end
