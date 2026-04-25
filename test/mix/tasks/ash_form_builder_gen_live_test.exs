defmodule Mix.Tasks.AshFormBuilder.Gen.LiveTest do
  use ExUnit.Case, async: false

  @task "ash_form_builder.gen.live"

  # Each test gets an isolated tmp dir; cleaned up on exit.
  setup do
    tmp =
      System.tmp_dir!()
      |> Path.join("afb_gen_live_#{System.unique_integer([:positive])}")

    File.mkdir_p!(tmp)
    on_exit(fn -> File.rm_rf!(tmp) end)

    # Tasks can only run once per session without reenable.
    Mix.Task.reenable(@task)

    {:ok, tmp: tmp}
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  # Run the task, suppress Mix.shell output, return {ex_content, heex_content}.
  defp run(args, out_dir) do
    Mix.Task.reenable(@task)

    ExUnit.CaptureIO.capture_io(fn ->
      Mix.Task.run(@task, args ++ ["--out", out_dir])
    end)

    ex = File.read!(Path.join(out_dir, "index.ex"))
    heex = File.read!(Path.join(out_dir, "index.html.heex"))
    {ex, heex}
  end

  # ---------------------------------------------------------------------------
  # Argument validation
  # ---------------------------------------------------------------------------

  describe "argument validation" do
    test "raises with no arguments" do
      assert_raise Mix.Error, ~r/Expected exactly two arguments/, fn ->
        ExUnit.CaptureIO.capture_io(fn -> Mix.Task.run(@task, []) end)
      end
    end

    test "raises with only one argument" do
      assert_raise Mix.Error, ~r/Expected exactly two arguments/, fn ->
        ExUnit.CaptureIO.capture_io(fn -> Mix.Task.run(@task, ["Accounts"]) end)
      end
    end

    test "raises when context starts with lowercase" do
      assert_raise Mix.Error, ~r/Context must start with an uppercase letter/, fn ->
        ExUnit.CaptureIO.capture_io(fn ->
          Mix.Task.run(@task, ["accounts", "User"])
        end)
      end
    end

    test "raises when resource starts with lowercase" do
      assert_raise Mix.Error, ~r/Resource must start with an uppercase letter/, fn ->
        ExUnit.CaptureIO.capture_io(fn ->
          Mix.Task.run(@task, ["Accounts", "user"])
        end)
      end
    end

    test "raises when context contains non-alphanumeric characters" do
      assert_raise Mix.Error, ~r/Context must start with an uppercase letter/, fn ->
        ExUnit.CaptureIO.capture_io(fn ->
          Mix.Task.run(@task, ["My-Context", "User"])
        end)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # File creation
  # ---------------------------------------------------------------------------

  describe "file creation (Accounts.User)" do
    setup %{tmp: tmp} do
      out = Path.join(tmp, "user_live")
      {ex, heex} = run(["Accounts", "User"], out)
      {:ok, out: out, ex: ex, heex: heex}
    end

    test "creates index.ex", %{out: out} do
      assert File.exists?(Path.join(out, "index.ex"))
    end

    test "creates index.html.heex", %{out: out} do
      assert File.exists?(Path.join(out, "index.html.heex"))
    end
  end

  # ---------------------------------------------------------------------------
  # index.ex — LiveView module
  # ---------------------------------------------------------------------------

  describe "index.ex content (Accounts.User)" do
    setup %{tmp: tmp} do
      {ex, _heex} = run(["Accounts", "User"], Path.join(tmp, "user_live"))
      {:ok, ex: ex}
    end

    test "declares the correct module name", %{ex: ex} do
      assert ex =~ "defmodule AshFormBuilderWeb.UserLive.Index do"
    end

    test "uses the correct web module", %{ex: ex} do
      assert ex =~ "use AshFormBuilderWeb, :live_view"
    end

    test "injects Cinder.UrlSync for URL state management", %{ex: ex} do
      assert ex =~ "use Cinder.UrlSync"
    end

    test "aliases the full resource module", %{ex: ex} do
      assert ex =~ "alias AshFormBuilder.Accounts.User"
    end

    test "declares @collection_id module attribute", %{ex: ex} do
      assert ex =~ ~s[@collection_id "user-collection"]
    end

    test "mount/3 sets url_state to false initially", %{ex: ex} do
      assert ex =~ "url_state: false"
    end

    test "mount/3 sets record and form to nil initially", %{ex: ex} do
      assert ex =~ "record: nil"
      assert ex =~ "form: nil"
    end

    test "handle_params/3 delegates to Cinder.UrlSync.handle_params", %{ex: ex} do
      assert ex =~ "Cinder.UrlSync.handle_params(params, uri, socket)"
    end

    test "apply_action :new builds AshPhoenix.Form.for_create", %{ex: ex} do
      assert ex =~ "AshPhoenix.Form.for_create"
      assert ex =~ ":create"
    end

    test "apply_action :edit loads the record with Ash.get! and builds for_update", %{ex: ex} do
      assert ex =~ "Ash.get!"
      assert ex =~ "AshPhoenix.Form.for_update"
      assert ex =~ ":update"
    end

    test "handle_info :form_submitted flashes success message", %{ex: ex} do
      assert ex =~ "{:form_submitted,"
      assert ex =~ "put_flash(:info,"
    end

    test "handle_info :form_submitted refreshes the Cinder collection", %{ex: ex} do
      assert ex =~ "Cinder.refresh_table(@collection_id)"
    end

    test "handle_info :form_submitted patches back to the index route", %{ex: ex} do
      assert ex =~ ~s[push_patch(to: ~p"/users")]
    end

    test "handle_event delete loads, destroys, and refreshes", %{ex: ex} do
      assert ex =~ ~s[handle_event("delete"]
      assert ex =~ "Ash.get!"
      assert ex =~ "Ash.destroy!"
      assert ex =~ "Cinder.refresh_table(@collection_id)"
    end

    test "delete handler flashes a success message", %{ex: ex} do
      # Two put_flash calls: one in handle_info, one in handle_event
      flash_count = ex |> String.split("put_flash(:info") |> length()
      assert flash_count >= 3
    end
  end

  # ---------------------------------------------------------------------------
  # index.html.heex — template
  # ---------------------------------------------------------------------------

  describe "index.html.heex content (Accounts.User)" do
    setup %{tmp: tmp} do
      {_ex, heex} = run(["Accounts", "User"], Path.join(tmp, "user_live"))
      {:ok, heex: heex}
    end

    test "has a <.header> containing the plural resource name", %{heex: heex} do
      assert heex =~ "<.header>"
      assert heex =~ "Users"
    end

    test "has a New [Resource] button linking to the /new route", %{heex: heex} do
      assert heex =~ "New User"
      assert heex =~ ~s[patch={~p"/users/new"}]
    end

    test "uses Cinder.collection with the correct resource module", %{heex: heex} do
      assert heex =~ "<Cinder.collection"
      assert heex =~ ~s[resource={AshFormBuilder.Accounts.User}]
    end

    test "Cinder.collection has the correct id attribute", %{heex: heex} do
      assert heex =~ ~s[id="user-collection"]
    end

    test "Cinder.collection receives url_state from assigns", %{heex: heex} do
      assert heex =~ "url_state={@url_state}"
    end

    test "Cinder.collection has default page_size of 25", %{heex: heex} do
      assert heex =~ "page_size={25}"
    end

    test "has an edit link that patches to /:id/edit", %{heex: heex} do
      assert heex =~ "Edit"
      assert heex =~ "/users/"
      assert heex =~ "/edit"
    end

    test "has a delete link with phx-click and data-confirm", %{heex: heex} do
      assert heex =~ ~s[phx-click="delete"]
      assert heex =~ "data-confirm="
    end

    test "modal is conditionally rendered for :new and :edit live_actions", %{heex: heex} do
      assert heex =~ ":if={@live_action in [:new, :edit]}"
    end

    test "modal id is resource-specific", %{heex: heex} do
      assert heex =~ ~s[id="user-modal"]
    end

    test "modal cancel patches back to the index route", %{heex: heex} do
      assert heex =~ ~s[on_cancel={JS.patch(~p"/users")}]
    end

    test "modal uses AshFormBuilder.FormComponent", %{heex: heex} do
      assert heex =~ "module={AshFormBuilder.FormComponent}"
    end

    test "FormComponent receives form assign", %{heex: heex} do
      assert heex =~ "form={@form}"
    end

    test "FormComponent receives the resource module", %{heex: heex} do
      assert heex =~ "resource={AshFormBuilder.Accounts.User}"
    end

    test "submit_label distinguishes create from update", %{heex: heex} do
      assert heex =~ "Create User"
      assert heex =~ "Save Changes"
    end
  end

  # ---------------------------------------------------------------------------
  # Option: --page-size
  # ---------------------------------------------------------------------------

  describe "--page-size option" do
    test "injects the specified page size into Cinder.collection", %{tmp: tmp} do
      {_ex, heex} =
        run(["Inventory", "Product", "--page-size", "50"], Path.join(tmp, "product_live"))

      assert heex =~ "page_size={50}"
    end

    test "default page size is 25 when option is omitted", %{tmp: tmp} do
      {_ex, heex} = run(["Inventory", "Product"], Path.join(tmp, "product_live"))
      assert heex =~ "page_size={25}"
    end
  end

  # ---------------------------------------------------------------------------
  # Multi-word and other contexts
  # ---------------------------------------------------------------------------

  describe "Blog.Post context" do
    setup %{tmp: tmp} do
      {ex, heex} = run(["Blog", "Post"], Path.join(tmp, "post_live"))
      {:ok, ex: ex, heex: heex}
    end

    test "index.ex has correct module name", %{ex: ex} do
      assert ex =~ "defmodule AshFormBuilderWeb.PostLive.Index do"
    end

    test "index.ex aliases correct resource module", %{ex: ex} do
      assert ex =~ "alias AshFormBuilder.Blog.Post"
    end

    test "index.ex collection id is post-specific", %{ex: ex} do
      assert ex =~ ~s[@collection_id "post-collection"]
    end

    test "heex uses correct resource module in Cinder.collection", %{heex: heex} do
      assert heex =~ "resource={AshFormBuilder.Blog.Post}"
    end

    test "heex uses post-specific route segments", %{heex: heex} do
      assert heex =~ ~s[patch={~p"/posts/new"}]
      assert heex =~ ~s[on_cancel={JS.patch(~p"/posts")}]
    end

    test "heex collection id is post-collection", %{heex: heex} do
      assert heex =~ ~s[id="post-collection"]
    end

    test "modal id is post-specific", %{heex: heex} do
      assert heex =~ ~s[id="post-modal"]
    end

    test "submit_label uses Post singular name", %{heex: heex} do
      assert heex =~ "Create Post"
    end

    test "header shows Posts plural", %{heex: heex} do
      assert heex =~ "Posts"
    end
  end

  # ---------------------------------------------------------------------------
  # CamelCase resource names
  # ---------------------------------------------------------------------------

  describe "CamelCase resource (BlogPost)" do
    setup %{tmp: tmp} do
      {ex, heex} = run(["Content", "BlogPost"], Path.join(tmp, "blog_post_live"))
      {:ok, ex: ex, heex: heex}
    end

    test "module name preserves CamelCase", %{ex: ex} do
      assert ex =~ "defmodule AshFormBuilderWeb.BlogPostLive.Index do"
    end

    test "alias uses the full module path", %{ex: ex} do
      assert ex =~ "alias AshFormBuilder.Content.BlogPost"
    end

    test "collection id is snake_case", %{heex: heex} do
      assert heex =~ ~s[id="blog_post-collection"]
    end

    test "route segment is snake_case", %{heex: heex} do
      assert heex =~ ~s[patch={~p"/blog_posts/new"}]
    end
  end
end
