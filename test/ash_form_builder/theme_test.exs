defmodule AshFormBuilder.ThemeTest do
  @moduledoc """
  Tests for theme behaviour and implementations.
  """

  use ExUnit.Case, async: true

  alias AshFormBuilder.Field

  describe "Default Theme" do
    test "implements render_field/2" do
      assert function_exported?(AshFormBuilder.Themes.Default, :render_field, 2)
    end

    test "implements render_nested/1" do
      assert function_exported?(AshFormBuilder.Themes.Default, :render_nested, 1)
    end

    test "render_nested returns nil (uses default)" do
      result = AshFormBuilder.Themes.Default.render_nested(%{})
      assert result == nil
    end
  end

  describe "MishkaTheme" do
    test "implements render_field/2" do
      assert function_exported?(AshFormBuilder.Theme.MishkaTheme, :render_field, 2)
    end

    test "implements render_nested/1" do
      assert function_exported?(AshFormBuilder.Theme.MishkaTheme, :render_nested, 1)
    end
  end

  describe "Field Type Mapping" do
    test "default theme handles all field types" do
      types = [
        :text_input,
        :textarea,
        :select,
        :multiselect_combobox,
        :checkbox,
        :number,
        :email,
        :password,
        :date,
        :datetime,
        :hidden,
        :url,
        :tel
      ]

      for type <- types do
        field = %Field{name: :test, type: type}
        form = %{}

        # Should not raise
        result = AshFormBuilder.Themes.Default.render_field(%{form: form, field: field}, [])
        assert is_struct(result, Phoenix.LiveView.Rendered)
      end
    end
  end
end
