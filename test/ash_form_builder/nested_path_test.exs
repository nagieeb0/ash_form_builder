defmodule AshFormBuilder.FormComponentNestedPathTest do
  @moduledoc """
  Tests for deeply nested form path parsing (3+ levels).
  """

  use ExUnit.Case, async: true

  alias AshFormBuilder.FormComponent

  describe "parse_nested_path/1" do
    test "parses simple field names" do
      assert FormComponent.parse_nested_path("tags") == [:tags]
      assert FormComponent.parse_nested_path("subtasks") == [:subtasks]
    end

    test "parses field with index" do
      assert FormComponent.parse_nested_path("subtasks[0]") == [{:subtasks, 0}]
      assert FormComponent.parse_nested_path("items[5]") == [{:items, 5}]
    end

    test "parses deeply nested paths (2 levels)" do
      assert FormComponent.parse_nested_path("subtasks[0].items") == [
               {:subtasks, 0},
               :items
             ]
    end

    test "parses deeply nested paths (3+ levels)" do
      assert FormComponent.parse_nested_path("subtasks[0].items[1].subitems") == [
               {:subtasks, 0},
               {:items, 1},
               :subitems
             ]

      assert FormComponent.parse_nested_path("level1[0].level2[1].level3[2].field") == [
               {:level1, 0},
               {:level2, 1},
               {:level3, 2},
               :field
             ]
    end

    test "parses mixed indexed and non-indexed segments" do
      assert FormComponent.parse_nested_path("parent[0].child.grandchild[1]") == [
               {:parent, 0},
               :child,
               {:grandchild, 1}
             ]
    end

    test "handles multiple digits in index" do
      assert FormComponent.parse_nested_path("items[10]") == [{:items, 10}]
      assert FormComponent.parse_nested_path("items[999]") == [{:items, 999}]
    end
  end

  describe "parse_path_segment/1 (private function via parse_nested_path)" do
    test "converts field names to atoms" do
      assert FormComponent.parse_nested_path("field_name") == [:field_name]
    end

    test "extracts index from bracket notation" do
      assert FormComponent.parse_nested_path("field[0]") == [{:field, 0}]
    end

    test "handles missing index (treats as atom)" do
      assert FormComponent.parse_nested_path("field[]") == [:field]
    end
  end
end
