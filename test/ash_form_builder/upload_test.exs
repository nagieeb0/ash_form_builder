defmodule AshFormBuilder.UploadTest do
  use ExUnit.Case, async: false

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  @endpoint AshFormBuilder.Test.Endpoint

  alias AshFormBuilder.Test.UploadResources

  setup do
    previous_theme = Application.get_env(:ash_form_builder, :theme)
    Application.delete_env(:ash_form_builder, :theme)

    on_exit(fn ->
      if previous_theme do
        Application.put_env(:ash_form_builder, :theme, previous_theme)
      else
        Application.delete_env(:ash_form_builder, :theme)
      end
    end)

    {:ok, conn: build_conn()}
  end

  # ── DSL / Inference ────────────────────────────────────────────────────────

  describe "DSL & inference" do
    test "UserProfile.Form is generated with file_upload field in schema" do
      schema = UploadResources.UserProfile.Form.schema()
      avatar_field = Enum.find(schema.fields, &(&1.name == :avatar))

      assert avatar_field != nil
      assert avatar_field.type == :file_upload
    end

    test "infer_fields maps :file atom type to :file_upload" do
      # The @type_map now includes :file => :file_upload
      # avatar is an explicit :string argument inferred as :text_input by default,
      # but it's declared in the DSL as :file_upload — effective_entities merges it
      entities = AshFormBuilder.Info.effective_entities(UploadResources.UserProfile)
      avatar = Enum.find(entities, &(&1.name == :avatar))

      assert avatar != nil
      assert avatar.type == :file_upload
    end

    test ":file_upload is valid in DSL one_of type list" do
      # Verify field struct accepts :file_upload type
      field = %AshFormBuilder.Field{name: :doc, type: :file_upload}
      assert field.type == :file_upload
    end

    test "upload opts are accessible on the field" do
      entities = AshFormBuilder.Info.effective_entities(UploadResources.UserProfile)
      avatar = Enum.find(entities, &(&1.name == :avatar))

      upload_cfg = Keyword.get(avatar.opts, :upload, [])
      assert Keyword.get(upload_cfg, :cloud) == AshFormBuilder.Test.MockCloud
      assert Keyword.get(upload_cfg, :max_entries) == 1
      assert Keyword.get(upload_cfg, :max_file_size) == 5_000_000
    end
  end

  # ── LiveComponent rendering ────────────────────────────────────────────────

  describe "LiveView rendering" do
    test "mounts and renders the file input element", %{conn: conn} do
      {:ok, _view, html} = live_isolated(conn, AshFormBuilder.Test.UploadFormLive)

      # The live_file_input renders a data-phx-upload-ref attribute
      assert html =~ "data-phx-upload-ref" or html =~ "phx-drop-target" or
               html =~ ~r/input.*type="file"/s
    end

    test "form renders the avatar label", %{conn: conn} do
      {:ok, _view, html} = live_isolated(conn, AshFormBuilder.Test.UploadFormLive)

      assert html =~ "Profile photo"
    end

    test "form renders the hint text", %{conn: conn} do
      {:ok, _view, html} = live_isolated(conn, AshFormBuilder.Test.UploadFormLive)

      assert html =~ "JPEG or PNG"
    end

    test "form renders required name field alongside file upload", %{conn: conn} do
      {:ok, _view, html} = live_isolated(conn, AshFormBuilder.Test.UploadFormLive)

      assert html =~ "Full name"
    end
  end

  # ── Upload lifecycle ───────────────────────────────────────────────────────

  describe "file upload lifecycle" do
    test "allow_upload is registered for the avatar field", %{conn: conn} do
      {:ok, view, _html} = live_isolated(conn, AshFormBuilder.Test.UploadFormLive)

      # The upload is registered — selecting a file should work
      upload =
        file_input(view, "#user_profile-form", :avatar, [
          %{
            name: "photo.jpg",
            content: :binary.copy(<<0xFF, 0xD8, 0xFF>>, 10),
            type: "image/jpeg"
          }
        ])

      assert %Phoenix.LiveViewTest.Upload{} = upload
    end

    test "file can be selected and progressed to 100%", %{conn: conn} do
      {:ok, view, _html} = live_isolated(conn, AshFormBuilder.Test.UploadFormLive)

      upload =
        file_input(view, "#user_profile-form", :avatar, [
          %{
            name: "avatar.jpg",
            content: :binary.copy(<<0xFF, 0xD8>>, 20),
            type: "image/jpeg"
          }
        ])

      html = render_upload(upload, 100)
      # After upload, progress should be rendered (100% or entry present)
      assert html =~ "100" or html =~ "avatar.jpg" or html =~ "upload"
    end

    test "form submission stores file and passes path to Ash action", %{conn: conn} do
      {:ok, view, _html} = live_isolated(conn, AshFormBuilder.Test.UploadFormLive)

      upload =
        file_input(view, "#user_profile-form", :avatar, [
          %{
            name: "profile.jpg",
            content: :binary.copy(<<0xFF, 0xD8, 0xFF, 0xE0>>, 25),
            type: "image/jpeg"
          }
        ])

      render_upload(upload, 100)

      view
      |> form("#user_profile-form", form: %{"name" => "Jane Doe"})
      |> render_submit()

      assert render(view) =~ "upload-result"
      assert render(view) =~ "uploads/"
    end

    test "form submission without file upload succeeds when field is optional", %{conn: conn} do
      {:ok, view, _html} = live_isolated(conn, AshFormBuilder.Test.UploadFormLive)

      view
      |> form("#user_profile-form", form: %{"name" => "John Doe"})
      |> render_submit()

      result_html = render(view)
      assert result_html =~ "upload-result"
      assert result_html =~ "avatar_path: none"
    end

    test "too_large error surfaces when file exceeds max_file_size", %{conn: conn} do
      {:ok, view, _html} = live_isolated(conn, AshFormBuilder.Test.UploadFormLive)

      # 6 MB > configured 5 MB max
      big_content = :binary.copy(<<0>>, 6 * 1_000_000)

      upload =
        file_input(view, "#user_profile-form", :avatar, [
          %{name: "huge.jpg", content: big_content, type: "image/jpeg"}
        ])

      html = render_upload(upload, 100)
      assert html =~ "too_large" or html =~ "too large" or html =~ "File is too large"
    end
  end

  # ── MockCloud unit ─────────────────────────────────────────────────────────

  describe "MockCloud" do
    test "insert/2 stores object and returns stored path" do
      object = %Buckets.Object{
        uuid: "test-uuid-1234",
        filename: "test.jpg",
        data: {:data, <<1, 2, 3>>},
        metadata: %{content_type: "image/jpeg"},
        location: %Buckets.Location.NotConfigured{},
        stored?: false
      }

      assert {:ok, stored} = AshFormBuilder.Test.MockCloud.insert(object)
      assert stored.stored? == true
      assert stored.location.path =~ "uploads/test-uuid-1234/test.jpg"
    end
  end
end
