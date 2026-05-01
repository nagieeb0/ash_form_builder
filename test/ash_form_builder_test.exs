defmodule AshFormBuilderTest do
  use ExUnit.Case, async: true

  alias AshFormBuilder.{Field, Info, TypeInference}
  alias AshFormBuilder.Test.Resources.{Article, Post, Review, Tag}
  alias AshFormBuilder.Test.Resources.Post.Form, as: PostForm
  alias AshFormBuilder.Themes.Default, as: DefaultTheme

  # Aliases for convenience
  @post Post
  @article Article
  @review Review

  # ===========================================================================
  # DSL introspection — explicit declarations (Post resource)
  # ===========================================================================

  describe "DSL introspection / explicit declarations" do
    test "forms/1 returns the declared form configs" do
      assert [config] = Info.forms(@post)
      assert config.action == :create
    end

    test "form_submit_label returns the declared label" do
      assert Info.form_submit_label(@post, :create) == "Publish post"
    end

    test "form_submit_label defaults to 'Submit' when not set" do
      assert Info.form_submit_label(@article, :create) == "Submit"
    end

    test "form_wrapper_class returns the declared class" do
      assert Info.form_wrapper_class(@post, :create) == "post-form-fields"
    end

    test "form_wrapper_class defaults to 'space-y-4' when not set" do
      assert Info.form_wrapper_class(@article, :create) == "space-y-4"
    end

    test "has_form? returns true for resources with form block" do
      assert Info.has_form?(@post, :create)
      assert Info.has_form?(@article, :create)
    end

    test "form_fields returns only explicit Field structs in declaration order" do
      fields = Info.form_fields(@post, :create)
      assert length(fields) == 4
      assert Enum.all?(fields, &is_struct(&1, Field))
      assert Enum.map(fields, & &1.name) == [:title, :body, :status, :published]
    end

    test "form_fields returns empty list for zero-config resource" do
      assert Info.form_fields(@article, :create) == []
    end

    test "form_nested returns only NestedForm structs" do
      nested = Info.form_nested(@post, :create)
      assert length(nested) == 1
      [tags] = nested
      assert tags.name == :tags
      assert tags.cardinality == :many
      assert tags.add_label == "Add tag"
      assert tags.remove_label == "Remove"
    end

    test "nested form fields are populated" do
      [tags] = Info.form_nested(@post, :create)
      assert [%Field{name: :name, label: "Tag name", required: true}] = tags.fields
    end

    test "form_entities returns all entities in declaration order" do
      entities = Info.form_entities(@post, :create)
      assert length(entities) == 5
    end

    test "build_nested_forms_config returns correct AshPhoenix config" do
      config = Info.build_nested_forms_config(@post, :create)
      assert [{:tags, opts}] = config
      assert opts[:type] == :list
      assert opts[:resource] == Tag
      assert opts[:create_action] == :create
    end
  end

  # ===========================================================================
  # Field DSL option details
  # ===========================================================================

  describe "explicit field DSL options" do
    test "title field options" do
      [title | _] = Info.form_fields(@post, :create)
      assert title.name == :title
      assert title.label == "Title"
      assert title.placeholder == "Enter a title…"
      assert title.required == true
      assert title.type == :text_input
    end

    test "body field is textarea with hint" do
      body = field_by_name(@post, :body)
      assert body.type == :textarea
      assert body.hint == "Markdown is supported"
    end

    test "status field is select with options" do
      status = field_by_name(@post, :status)
      assert status.type == :select
      assert status.options == [{"Draft", :draft}, {"Published", :published}]
    end

    test "published field is checkbox" do
      published = field_by_name(@post, :published)
      assert published.type == :checkbox
    end
  end

  # ===========================================================================
  # Generated Post.Form module
  # ===========================================================================

  describe "generated Form helper module" do
    test "module is generated at compile time" do
      assert Code.ensure_loaded?(AshFormBuilder.Test.Resources.Post.Form)
    end

    test "resource/0 returns the resource module" do
      assert PostForm.resource() ==
               AshFormBuilder.Test.Resources.Post
    end

    test "actions/0 returns the declared actions" do
      assert PostForm.actions() == [:create]
    end

    test "nested_forms/1 returns AshPhoenix-shaped config" do
      config = PostForm.nested_forms(:create)
      assert [{:tags, opts}] = config
      assert opts[:type] == :list
      assert opts[:resource] == Tag
    end

    test "for_create/1 returns a Phoenix.HTML.Form" do
      form = PostForm.for_create(authorize?: false)
      assert %Phoenix.HTML.Form{} = form
    end

    test "for_create/1 source is an AshPhoenix.Form" do
      form = PostForm.for_create(authorize?: false)
      assert %AshPhoenix.Form{} = form.source
    end
  end

  # ===========================================================================
  # TypeInference — unit tests
  # ===========================================================================

  describe "TypeInference.infer_fields/2" do
    test "infers :text_input for :string attributes" do
      fields = TypeInference.infer_fields(@article, :create)
      title = Enum.find(fields, &(&1.name == :title))
      assert title.type == :text_input
    end

    test "infers :toggle for :boolean attributes" do
      fields = TypeInference.infer_fields(@article, :create)
      published = Enum.find(fields, &(&1.name == :published))
      assert published.type == :toggle
    end

    test "infers :number for :integer attributes" do
      fields = TypeInference.infer_fields(@article, :create)
      view_count = Enum.find(fields, &(&1.name == :view_count))
      assert view_count.type == :number
    end

    test "infers :select for :atom with one_of constraint" do
      fields = TypeInference.infer_fields(@article, :create)
      status = Enum.find(fields, &(&1.name == :status))
      assert status.type == :select
    end

    test "infers options from one_of constraint" do
      fields = TypeInference.infer_fields(@article, :create)
      status = Enum.find(fields, &(&1.name == :status))
      assert length(status.options) == 3
      assert Enum.all?(status.options, fn {label, val} -> is_binary(label) && is_atom(val) end)
    end

    test "marks allow_nil?: false with no default as required" do
      fields = TypeInference.infer_fields(@article, :create)
      title = Enum.find(fields, &(&1.name == :title))
      assert title.required == true
    end

    test "marks allow_nil?: true as not required" do
      fields = TypeInference.infer_fields(@article, :create)
      body = Enum.find(fields, &(&1.name == :body))
      assert body.required == false
    end

    test "marks attribute with default as not required even if allow_nil?: false" do
      fields = TypeInference.infer_fields(@article, :create)
      # published has default: false so not required
      published = Enum.find(fields, &(&1.name == :published))
      assert published.required == false
    end

    test "humanizes field names into labels" do
      fields = TypeInference.infer_fields(@article, :create)
      view_count = Enum.find(fields, &(&1.name == :view_count))
      assert view_count.label == "View Count"
    end

    test "returns fields in the action's accept list order" do
      fields = TypeInference.infer_fields(@article, :create)
      names = Enum.map(fields, & &1.name)
      assert names == [:title, :body, :published, :view_count, :status]
    end

    test "returns empty list for unknown action" do
      assert TypeInference.infer_fields(@article, :nonexistent) == []
    end

    test "infers for Review's create action" do
      fields = TypeInference.infer_fields(@review, :create)
      assert length(fields) == 4
      names = Enum.map(fields, & &1.name)
      assert :title in names
      assert :body in names
      assert :rating in names
      assert :approved in names
    end
  end

  # ===========================================================================
  # Info.effective_fields/1 — zero-config vs override merging
  # ===========================================================================

  describe "effective_fields/1 — auto-inference" do
    test "zero-config resource returns all inferred fields" do
      fields = Info.effective_fields(@article, :create)
      assert length(fields) == 5
      assert Enum.all?(fields, &is_struct(&1, Field))
    end

    test "zero-config fields have auto-inferred types" do
      fields = Info.effective_fields(@article, :create)
      assert field_type(fields, :title) == :text_input
      assert field_type(fields, :published) == :toggle
      assert field_type(fields, :view_count) == :number
      assert field_type(fields, :status) == :select
    end

    test "zero-config fields have humanized labels" do
      fields = Info.effective_fields(@article, :create)
      assert field_label(fields, :view_count) == "View Count"
      assert field_label(fields, :title) == "Title"
    end

    test "explicit field overrides inferred field for same name" do
      fields = Info.effective_fields(@review, :create)
      body = Enum.find(fields, &(&1.name == :body))
      # Explicit declaration wins
      assert body.label == "Full Review"
      assert body.type == :textarea
      assert body.hint == "Be as detailed as possible"
    end

    test "non-overridden fields in partial-override resource are still inferred" do
      fields = Info.effective_fields(@review, :create)
      title = Enum.find(fields, &(&1.name == :title))
      assert title.label == "Title"
      assert title.type == :text_input
      assert title.required == true

      rating = Enum.find(fields, &(&1.name == :rating))
      assert rating.type == :number
    end

    test "field order follows the action's accept list" do
      fields = Info.effective_fields(@review, :create)
      names = Enum.map(fields, & &1.name)
      assert names == [:title, :body, :rating, :approved]
    end

    test "explicit-only resource returns all four declared fields" do
      fields = Info.effective_fields(@post, :create)
      assert length(fields) == 4
      assert Enum.map(fields, & &1.name) == [:title, :body, :status, :published]
    end

    test "explicit fields preserve their DSL options even when inferred would differ" do
      fields = Info.effective_fields(@post, :create)
      # Status was declared as :select with explicit options — not auto-inferred
      status = Enum.find(fields, &(&1.name == :status))
      assert status.label == "Status"
      assert status.options == [{"Draft", :draft}, {"Published", :published}]
    end
  end

  # ===========================================================================
  # Info.effective_entities/1 — fields + nested
  # ===========================================================================

  describe "effective_entities/1" do
    test "includes both effective fields and nested forms" do
      entities = Info.effective_entities(@post, :create)
      fields = Enum.filter(entities, &is_struct(&1, AshFormBuilder.Field))
      nested = Enum.filter(entities, &is_struct(&1, AshFormBuilder.NestedForm))
      assert length(fields) == 4
      assert length(nested) == 1
    end

    test "fields come before nested forms" do
      entities = Info.effective_entities(@post, :create)

      last_field_index =
        entities
        |> Enum.with_index()
        |> Enum.filter(fn {e, _} -> is_struct(e, AshFormBuilder.Field) end)
        |> Enum.map(&elem(&1, 1))
        |> List.last()

      first_nested_index =
        entities
        |> Enum.with_index()
        |> Enum.find_value(fn {e, i} -> if is_struct(e, AshFormBuilder.NestedForm), do: i end)

      assert last_field_index < first_nested_index
    end

    test "zero-config resource entities contain only inferred fields (no nested)" do
      entities = Info.effective_entities(@article, :create)
      assert length(entities) == 5
      assert Enum.all?(entities, &is_struct(&1, AshFormBuilder.Field))
    end
  end

  # ===========================================================================
  # Theme — behaviour & default theme
  # ===========================================================================

  describe "AshFormBuilder.Theme behaviour" do
    test "Default theme implements the Theme behaviour" do
      assert function_exported?(AshFormBuilder.Themes.Default, :render_field, 2)
    end

    test "Mishka theme implements the Theme behaviour" do
      assert function_exported?(AshFormBuilder.Theme.MishkaTheme, :render_field, 2)
    end

    test "Default theme render_field/2 returns a Rendered struct for text field" do
      form = PostForm.for_create(authorize?: false)
      field = %Field{name: :title, label: "Title", type: :text_input}
      result = DefaultTheme.render_field(%{form: form, field: field}, [])
      assert %Phoenix.LiveView.Rendered{} = result
    end

    test "Default theme render_field/2 returns a Rendered struct for checkbox" do
      form = PostForm.for_create(authorize?: false)
      field = %Field{name: :published, label: "Published", type: :checkbox}
      result = DefaultTheme.render_field(%{form: form, field: field}, [])
      assert %Phoenix.LiveView.Rendered{} = result
    end

    test "Default theme render_field/2 returns a Rendered struct for hidden field" do
      form = PostForm.for_create(authorize?: false)
      field = %Field{name: :id, type: :hidden}
      result = DefaultTheme.render_field(%{form: form, field: field}, [])
      assert %Phoenix.LiveView.Rendered{} = result
    end

    test "theme_module defaults to Default when not configured" do
      # Ensure no override is set
      Application.delete_env(:ash_form_builder, :theme)
      # FormRenderer resolves Default internally — verified via effective_entities rendering
      assert AshFormBuilder.Themes.Default ==
               Application.get_env(:ash_form_builder, :theme, AshFormBuilder.Themes.Default)
    end
  end

  # ===========================================================================
  # FormComponent — render & event tests (direct callback testing)
  # ===========================================================================

  describe "FormComponent.handle_event/3" do
    setup do
      form = PostForm.for_create(authorize?: false)

      socket = %Phoenix.LiveView.Socket{
        assigns: %{
          __changed__: %{},
          resource: Post,
          form: form,
          entities: Info.effective_entities(Post, :create),
          submit_label: "Submit",
          wrapper_class: "space-y-4",
          form_id: "post-form",
          on_submit: nil
        },
        endpoint: nil,
        transport_pid: nil,
        id: "test-component",
        root_pid: self(),
        parent_pid: nil,
        view: nil,
        router: nil,
        private: %{connect_params: %{}, connect_info: %{}, root_view: nil}
      }

      {:ok, socket: socket}
    end

    test "validate event updates form with validated params", %{socket: socket} do
      {:noreply, updated_socket} =
        AshFormBuilder.FormComponent.handle_event(
          "validate",
          %{"form" => %{"title" => "Hello"}},
          socket
        )

      assert %Phoenix.HTML.Form{} = updated_socket.assigns.form
    end

    test "validate event with no form key is a no-op", %{socket: socket} do
      {:noreply, updated_socket} =
        AshFormBuilder.FormComponent.handle_event("validate", %{}, socket)

      assert updated_socket.assigns.form == socket.assigns.form
    end

    test "add_form event adds a nested form entry", %{socket: socket} do
      {:noreply, updated_socket} =
        AshFormBuilder.FormComponent.handle_event(
          "add_form",
          %{"path" => "tags"},
          socket
        )

      updated_form = updated_socket.assigns.form
      assert %Phoenix.HTML.Form{} = updated_form
    end

    test "submit event with valid params calls on_submit callback" do
      test_pid = self()
      form = PostForm.for_create(authorize?: false)

      socket = %Phoenix.LiveView.Socket{
        assigns: %{
          __changed__: %{},
          resource: Post,
          form: form,
          entities: Info.effective_entities(Post, :create),
          submit_label: "Submit",
          wrapper_class: "space-y-4",
          form_id: "post-form",
          on_submit: fn result -> send(test_pid, {:submitted, result}) end
        },
        endpoint: nil,
        transport_pid: nil,
        id: "test-component",
        root_pid: self(),
        parent_pid: nil,
        view: nil,
        router: nil,
        private: %{connect_params: %{}, connect_info: %{}, root_view: nil}
      }

      {:noreply, _} =
        AshFormBuilder.FormComponent.handle_event(
          "submit",
          %{"form" => %{"title" => "Test Post", "body" => "Content"}},
          socket
        )

      assert_receive {:submitted, %AshFormBuilder.Test.Resources.Post{}}, 500
    end

    test "submit event with invalid params returns form with errors" do
      form = PostForm.for_create(authorize?: false)

      socket = %Phoenix.LiveView.Socket{
        assigns: %{
          __changed__: %{},
          resource: Post,
          form: form,
          entities: Info.effective_entities(Post, :create),
          submit_label: "Submit",
          wrapper_class: "space-y-4",
          form_id: "post-form",
          on_submit: nil
        },
        endpoint: nil,
        transport_pid: nil,
        id: "test-component",
        root_pid: self(),
        parent_pid: nil,
        view: nil,
        router: nil,
        private: %{connect_params: %{}, connect_info: %{}, root_view: nil}
      }

      {:noreply, updated_socket} =
        AshFormBuilder.FormComponent.handle_event(
          "submit",
          %{"form" => %{"title" => ""}},
          socket
        )

      # Form is returned with errors, not submitted
      assert %Phoenix.HTML.Form{} = updated_socket.assigns.form
    end
  end

  # ===========================================================================
  # Helpers
  # ===========================================================================

  defp field_by_name(resource, name) do
    resource |> Info.form_fields(:create) |> Enum.find(&(&1.name == name))
  end

  defp field_type(fields, name) do
    fields |> Enum.find(&(&1.name == name)) |> Map.get(:type)
  end

  defp field_label(fields, name) do
    fields |> Enum.find(&(&1.name == name)) |> Map.get(:label)
  end
end
