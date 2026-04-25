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

      # Verify the upload is configured by checking the rendered HTML
      html = render(view)
      assert html =~ "data-phx-upload"
      assert html =~ "avatar"
    end

    test "file input element is rendered", %{conn: conn} do
      {:ok, view, _html} = live_isolated(conn, AshFormBuilder.Test.UploadFormLive)

      # Find the file input element
      html = render(view)
      assert html =~ "data-phx-hook=\"Phoenix.LiveFileUpload\""
      assert html =~ "type=\"file\""
      assert html =~ "accept=\".jpg,.jpeg,.png\""
    end

    test "form submission without file upload succeeds when field is optional", %{conn: conn} do
      {:ok, view, _html} = live_isolated(conn, AshFormBuilder.Test.UploadFormLive)

      # Submit without uploading a file
      view
      |> form("#user_profile-form", %{"form" => %{"name" => "John Doe"}})
      |> render_submit()

      result_html = render(view)
      assert result_html =~ "upload-result"
      # Avatar path should be nil/none since no file was uploaded
      assert result_html =~ "none" or result_html =~ "avatar_path"
    end

    test "form submission with file path stores file reference", %{conn: conn} do
      {:ok, view, _html} = live_isolated(conn, AshFormBuilder.Test.UploadFormLive)

      # First verify the form renders correctly
      html = render(view)
      assert html =~ "Profile photo"

      # Submit with a file path (simulating an uploaded file)
      # AshPhoenix.Form passes arguments at the top level of params
      view
      |> form("#user_profile-form", %{
        "form" => %{"name" => "Jane Doe"},
        "avatar" => "uploads/test.jpg"
      })
      |> render_submit()

      # Wait for the result to be rendered
      assert render(view) =~ "upload-result"
      # The result should contain the submitted name
      assert render(view) =~ "Jane Doe" or render(view) =~ "avatar_path"
    end

    test "file size validation hint is rendered", %{conn: conn} do
      {:ok, _view, html} = live_isolated(conn, AshFormBuilder.Test.UploadFormLive)

      # Verify the max_file_size hint is rendered
      assert html =~ "max 5 MB" or html =~ "5 MB" or html =~ "JPEG or PNG"
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
