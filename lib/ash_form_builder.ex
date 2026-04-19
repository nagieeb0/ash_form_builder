defmodule AshFormBuilder do
  @moduledoc """
  A Spark DSL extension for Ash Framework that automatically generates
  Phoenix LiveView forms from resource definitions.

  ## Installation

  Add the extension to your resource:

      defmodule MyApp.Blog.Post do
        use Ash.Resource,
          domain: MyApp.Blog,
          extensions: [AshFormBuilder]

        # ... attributes, relationships, actions ...

        form do
          action :create

          field :title do
            label "Title"
            placeholder "Post title…"
            required true
          end

          field :body do
            label "Body"
            type :textarea
          end

          field :status do
            label "Status"
            type :select
            options [{"Draft", :draft}, {"Published", :published}]
          end

          nested :tags do
            label "Tags"
            cardinality :many
            add_label "Add tag"
            remove_label "✕"

            field :name do
              label "Tag name"
              required true
            end
          end
        end
      end

  ## Creating a form in your LiveView

      def mount(_params, _session, socket) do
        # The generated helper pre-configures nested forms for you:
        form = MyApp.Blog.Post.Form.for_create(actor: socket.assigns.current_user)
        {:ok, assign(socket, form: form)}
      end

  ## Rendering

      # In the LiveView template:
      <.live_component
        module={AshFormBuilder.FormComponent}
        id="create-post"
        resource={MyApp.Blog.Post}
        form={@form}
      />

      # Handle the success message:
      def handle_info({:form_submitted, MyApp.Blog.Post, post}, socket) do
        {:noreply, push_navigate(socket, to: ~p"/posts/\#{post}")}
      end

  ## Custom callback instead of messaging

      <.live_component
        module={AshFormBuilder.FormComponent}
        id="create-post"
        resource={MyApp.Blog.Post}
        form={@form}
        on_submit={fn post -> send(self(), {:created, post}) end}
      />

  ## DSL reference

  ### `form` section options

  | option          | type   | default    | description |
  |-----------------|--------|------------|-------------|
  | `action`        | atom   | required   | Ash action to target |
  | `submit_label`  | string | `"Submit"` | Submit button label |
  | `module`        | atom   | —          | Override generated module name |
  | `form_id`       | string | —          | HTML `id` for the `<form>` |
  | `wrapper_class` | string | `"space-y-4"` | CSS class on the fields div |

  ### `field` options

  | option          | type    | default        | description |
  |-----------------|---------|----------------|-------------|
  | `label`         | string  | —              | Input label |
  | `type`          | atom    | `:text_input`  | Input type (see below) |
  | `placeholder`   | string  | —              | Placeholder text |
  | `required`      | boolean | `false`        | Show required indicator |
  | `options`       | list    | `[]`           | Options for `:select` |
  | `class`         | string  | —              | Extra class on the `<input>` |
  | `wrapper_class` | string  | —              | Extra class on wrapper `<div>` |
  | `hint`          | string  | —              | Help text below input |

  Field types: `:text_input`, `:textarea`, `:select`, `:checkbox`,
  `:number`, `:email`, `:password`, `:date`, `:datetime`, `:hidden`,
  `:url`, `:tel`.

  ### `nested` options

  | option           | type   | default    | description |
  |------------------|--------|------------|-------------|
  | `relationship`   | atom   | `:name`    | Relationship on parent resource |
  | `cardinality`    | atom   | `:many`    | `:many` or `:one` |
  | `label`          | string | —          | Fieldset legend |
  | `add_label`      | string | `"Add"`    | Add-button label |
  | `remove_label`   | string | `"Remove"` | Remove-button label |
  | `create_action`  | atom   | `:create`  | Nested resource create action |
  | `update_action`  | atom   | `:update`  | Nested resource update action |
  | `class`          | string | —          | Extra class on `<fieldset>` |
  """

  use Spark.Dsl.Extension,
    sections: AshFormBuilder.Dsl.sections(),
    transformers: AshFormBuilder.Dsl.transformers()
end
