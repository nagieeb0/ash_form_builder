defmodule Mix.Tasks.AshForm.Gen.LiveTest do
  use ExUnit.Case, async: false

  @task "ash_form.gen.live"
  @resource "AshFormBuilder.Accounts.User"

  setup do
    tmp =
      System.tmp_dir!()
      |> Path.join("afb_gen_live_#{System.unique_integer([:positive])}")

    File.mkdir_p!(tmp)
    on_exit(fn -> File.rm_rf!(tmp) end)

    Mix.Task.reenable(@task)

    {:ok, tmp: tmp}
  end

  # Run the task, capture output, return {ex, heex}.
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
    test "raises when --resource is missing" do
      assert_raise Mix.Error, ~r/Missing required `--resource`/, fn ->
        ExUnit.CaptureIO.capture_io(fn -> Mix.Task.run(@task, []) end)
      end
    end

    test "raises when resource is not a fully-qualified module" do
      assert_raise Mix.Error, ~r/fully-qualified module name/, fn ->
        ExUnit.CaptureIO.capture_io(fn ->
          Mix.Task.run(@task, ["-r", "user"])
        end)
      end
    end

    test "raises when resource contains non-alphanumeric characters" do
      assert_raise Mix.Error, ~r/fully-qualified module name/, fn ->
        ExUnit.CaptureIO.capture_io(fn ->
          Mix.Task.run(@task, ["-r", "MyApp.Bad-Module"])
        end)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # File creation
  # ---------------------------------------------------------------------------

  describe "file creation (-r AshFormBuilder.Accounts.User)" do
    setup %{tmp: tmp} do
      out = Path.join(tmp, "user_live")
      {ex, heex} = run(["-r", @resource], out)
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

  describe "index.ex content" do
    setup %{tmp: tmp} do
      {ex, _heex} = run(["-r", @resource], Path.join(tmp, "user_live"))
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

    test "mount/3 sets url_state false initially", %{ex: ex} do
      assert ex =~ "url_state: false"
    end

    test "apply_action :new builds via Resource.Form.for_create", %{ex: ex} do
      assert ex =~ "User.Form.for_create"
    end

    test "apply_action :edit loads with Ash.get! and uses Form.for_update", %{ex: ex} do
      assert ex =~ "Ash.get!"
      assert ex =~ "User.Form.for_update"
    end

    test "handle_info :form_submitted flashes success", %{ex: ex} do
      assert ex =~ "{:form_submitted,"
      assert ex =~ "put_flash(:info,"
    end

    test "handle_info :form_submitted refreshes the Cinder collection", %{ex: ex} do
      assert ex =~ "Cinder.refresh_table(@collection_id)"
    end

    test "handle_info :form_submitted patches back to index", %{ex: ex} do
      assert ex =~ ~s[push_patch(to: ~p"/users")]
    end

    test "handle_event delete works", %{ex: ex} do
      assert ex =~ ~s[handle_event("delete"]
      assert ex =~ "Ash.get!"
      assert ex =~ "Ash.destroy!"
    end
  end

  # ---------------------------------------------------------------------------
  # index.html.heex — template
  # ---------------------------------------------------------------------------

  describe "index.html.heex content" do
    setup %{tmp: tmp} do
      {_ex, heex} = run(["-r", @resource], Path.join(tmp, "user_live"))
      {:ok, heex: heex}
    end

    test "renders the page header", %{heex: heex} do
      assert heex =~ "<.header>"
      assert heex =~ "Users"
    end

    test "renders the New button", %{heex: heex} do
      assert heex =~ "New User"
    end

    test "uses Cinder.collection with the resource", %{heex: heex} do
      assert heex =~ "<Cinder.collection"
      assert heex =~ "resource={AshFormBuilder.Accounts.User}"
    end

    test "renders the modal with FormComponent", %{heex: heex} do
      assert heex =~ "<.modal"
      assert heex =~ "AshFormBuilder.FormComponent"
    end

    test "uses dynamic submit_label for new vs edit", %{heex: heex} do
      assert heex =~ "Create User"
      assert heex =~ "Save Changes"
    end
  end

  # ---------------------------------------------------------------------------
  # Theme / accent / transitions flags propagate to template
  # ---------------------------------------------------------------------------

  describe "--theme / --accent / --transitions flags" do
    test "writes accent attr when --accent passed", %{tmp: tmp} do
      {_ex, heex} = run(["-r", @resource, "--accent", "teal"], Path.join(tmp, "u1"))
      assert heex =~ "accent={:teal}"
    end

    test "writes transitions attr when --transitions passed", %{tmp: tmp} do
      {_ex, heex} =
        run(["-r", @resource, "--transitions", "smooth"], Path.join(tmp, "u2"))

      assert heex =~ "transitions={:smooth}"
    end

    test "writes theme attr as atom when short form passed", %{tmp: tmp} do
      {_ex, heex} = run(["-r", @resource, "--theme", "shadcn"], Path.join(tmp, "u3"))
      assert heex =~ "theme={:shadcn}"
    end

    test "writes theme attr as module when capitalized form passed", %{tmp: tmp} do
      {_ex, heex} =
        run(
          ["-r", @resource, "--theme", "AshFormBuilder.Themes.Shadcn"],
          Path.join(tmp, "u4")
        )

      assert heex =~ "theme={AshFormBuilder.Themes.Shadcn}"
    end
  end

  # ---------------------------------------------------------------------------
  # --page-size flag
  # ---------------------------------------------------------------------------

  describe "--page-size flag" do
    test "uses default 25 when not specified", %{tmp: tmp} do
      {_ex, heex} = run(["-r", @resource], Path.join(tmp, "u5"))
      assert heex =~ "page_size={25}"
    end

    test "uses provided page size", %{tmp: tmp} do
      {_ex, heex} = run(["-r", @resource, "-p", "100"], Path.join(tmp, "u6"))
      assert heex =~ "page_size={100}"
    end
  end
end
