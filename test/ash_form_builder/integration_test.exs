defmodule AshFormBuilder.IntegrationTest do
  use ExUnit.Case, async: true

  alias AshFormBuilder.{Infer, Info}
  alias AshFormBuilder.Test.Domain
  alias AshFormBuilder.Test.Domain.Clinic

  setup do
    # Ensure all modules are loaded before running tests
    Code.ensure_loaded?(Clinic)
    Code.ensure_loaded?(Domain)
    :ok
  end

  describe "Infer vs DSL merge" do
    test "Infer.infer_fields/3 uses Ash metadata only (no DSL labels)" do
      # Infer.infer_fields only looks at action.accept, not DSL declarations
      # specialties is not in accept, so it won't be found by Infer
      inferred_specialties =
        Infer.infer_fields(Clinic, :create) |> Enum.find(&(&1.name == :specialties))

      # Since specialties is not in action.accept, Infer won't find it
      # Note: manage_relationship configuration is not exposed in action metadata in Ash 3.0
      assert inferred_specialties == nil
    end

    test "Info.effective_fields/1 applies DSL overrides on top of inference" do
      effective_specialties =
        Info.effective_fields(Clinic) |> Enum.find(&(&1.name == :specialties))

      assert effective_specialties.label == "Specialties (DSL)"
      assert Keyword.get(effective_specialties.opts, :search_event) == "search_specialties"
      assert Keyword.get(effective_specialties.opts, :debounce) == 150
    end

    test "Infer.infer_fields includes action arguments" do
      # Infer should detect action arguments like referral_code
      fields = Infer.infer_fields(Clinic, :create)
      referral_field = Enum.find(fields, &(&1.name == :referral_code))

      assert referral_field != nil
      assert referral_field.type == :text_input
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
