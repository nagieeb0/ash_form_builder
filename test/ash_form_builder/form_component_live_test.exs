defmodule AshFormBuilder.FormComponentLiveTest do
  use ExUnit.Case, async: false

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  @endpoint AshFormBuilder.Test.Endpoint

  alias AshFormBuilder.Test.Domain.Clinic

  setup do
    previous_theme = Application.get_env(:ash_form_builder, :theme)
    Application.put_env(:ash_form_builder, :theme, AshFormBuilder.Theme.MishkaTheme)

    on_exit(fn ->
      if previous_theme == nil do
        Application.delete_env(:ash_form_builder, :theme)
      else
        Application.put_env(:ash_form_builder, :theme, previous_theme)
      end
    end)

    {:ok, conn: build_conn()}
  end

  describe "LiveView rendering (MishkaTheme)" do
    test "renders Mishka stubs for text and combobox fields", %{conn: conn} do
      {:ok, _view, html} = live_isolated(conn, AshFormBuilder.Test.ClinicFormLive)

      assert html =~ "mishka-textfield-stub"
      assert html =~ "mishka-combobox-stub"
      assert html =~ "Clinic name"
      assert html =~ "Specialties (DSL)"
    end

    test "combobox search wiring exposes phx-change on the search input", %{conn: conn} do
      {:ok, view, _html} = live_isolated(conn, AshFormBuilder.Test.ClinicFormLive)

      html =
        view
        |> element(".mishka-combobox-input-stub")
        |> render_change(%{"query" => "card"})

      assert html =~ "phx-change=\"search_specialties\""
    end

    test "add_form and remove_form manage nested subtask forms", %{conn: conn} do
      {:ok, view, _html} = live_isolated(conn, AshFormBuilder.Test.ClinicFormLive)

      assert view |> element(".btn-add-nested") |> has_element?()

      view |> element(".btn-add-nested") |> render_click()
      assert render(view) =~ "mishka-textfield-stub"

      assert view |> element(".btn-remove-nested") |> has_element?()
      view |> element(".btn-remove-nested") |> render_click()
    end

    test "validation errors surface on required fields", %{conn: conn} do
      {:ok, view, _html} = live_isolated(conn, AshFormBuilder.Test.ClinicFormLive)

      html =
        view
        |> form("#clinic-form", clinic: %{"name" => ""})
        |> render_submit()

      assert html =~ "can't be blank" or html =~ "is invalid" or html =~ "required"
    end

    test "successful submit notifies the parent LiveView", %{conn: conn} do
      {:ok, view, _html} = live_isolated(conn, AshFormBuilder.Test.ClinicFormLive)

      _html =
        view
        |> form("#clinic-form", clinic: %{"name" => "Downtown Clinic", "phone" => "555-0100"})
        |> render_submit()

      assert render(view) =~ "last-submission"
    end
  end

  # Creatable Combobox tests are skipped due to many_to_many relationship configuration issues
  # The core functionality is tested in the InferTest and FormComponent event handler tests
end
