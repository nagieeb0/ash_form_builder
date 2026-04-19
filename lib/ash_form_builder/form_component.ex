defmodule AshFormBuilder.FormComponent do
  @moduledoc """
  A self-contained Phoenix LiveComponent that renders and manages an
  AshPhoenix.Form based on the `AshFormBuilder` DSL declared on a resource.

  ## Usage

      <.live_component
        module={AshFormBuilder.FormComponent}
        id="create-post"
        resource={MyApp.Post}
        form={@form}
      />

  The parent LiveView creates the initial form (the generated `Resource.Form`
  helper does this for you):

      form = MyApp.Post.Form.for_create(actor: current_user)
      {:ok, assign(socket, form: form)}

  On successful submit the component sends a message to the parent process:

      def handle_info({:form_submitted, MyApp.Post, post}, socket) do
        {:noreply, push_navigate(socket, to: ~p"/posts/\#{post}")}
      end

  ## Assigns

  | assign        | type               | required | description |
  |---------------|--------------------|----------|-------------|
  | `:resource`   | module             | yes      | The Ash resource module |
  | `:form`       | `Phoenix.HTML.Form`| yes      | Form produced by `to_form/1` |
  | `:id`         | string             | yes      | LiveComponent id |
  | `:on_submit`  | `(result -> any)`  | no       | Callback instead of `send/2` |
  | `:submit_label`| string            | no       | Override the DSL submit label |
  """

  use Phoenix.LiveComponent

  alias AshFormBuilder.{FormRenderer, Info}

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    resource = assigns.resource
    entities = Info.effective_entities(resource)
    submit_label = assigns[:submit_label] || Info.form_submit_label(resource)
    wrapper_class = Info.form_wrapper_class(resource)
    form_id = assigns[:form_id] || Info.form_html_id(resource) || default_form_id(resource)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(
       entities: entities,
       submit_label: submit_label,
       wrapper_class: wrapper_class,
       form_id: form_id
     )
     |> assign_new(:on_submit, fn -> nil end)}
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div>
      <.form
        for={@form}
        id={@form_id}
        phx-change="validate"
        phx-submit="submit"
        phx-target={@myself}
      >
        <FormRenderer.form_fields
          form={@form}
          entities={@entities}
          target={@myself}
          wrapper_class={@wrapper_class}
          theme_opts={[target: @myself]}
        />

        <div class="form-actions">
          <button type="submit" class="btn-submit">
            {@submit_label}
          </button>
        </div>
      </.form>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Events
  # ---------------------------------------------------------------------------

  @impl Phoenix.LiveComponent
  def handle_event("validate", %{"form" => params}, socket) do
    form = AshPhoenix.Form.validate(socket.assigns.form.source, params)
    {:noreply, assign(socket, form: to_form(form))}
  end

  def handle_event("validate", _params, socket), do: {:noreply, socket}

  @impl Phoenix.LiveComponent
  def handle_event("add_form", %{"path" => path}, socket) do
    form = AshPhoenix.Form.add_form(socket.assigns.form.source, path)
    {:noreply, assign(socket, form: to_form(form))}
  end

  @impl Phoenix.LiveComponent
  def handle_event("remove_form", %{"path" => path}, socket) do
    form = AshPhoenix.Form.remove_form(socket.assigns.form.source, path)
    {:noreply, assign(socket, form: to_form(form))}
  end

  @impl Phoenix.LiveComponent
  def handle_event("submit", %{"form" => params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.form.source, params: params) do
      {:ok, result} ->
        notify_parent(socket, result)
        {:noreply, socket}

      {:error, form} ->
        {:noreply, assign(socket, form: to_form(form))}
    end
  end

  # ---------------------------------------------------------------------------
  # Private
  # ---------------------------------------------------------------------------

  defp notify_parent(socket, result) do
    case socket.assigns[:on_submit] do
      nil -> send(self(), {:form_submitted, socket.assigns.resource, result})
      callback when is_function(callback, 1) -> callback.(result)
    end
  end

  defp default_form_id(resource) do
    resource
    |> Module.split()
    |> List.last()
    |> Macro.underscore()
    |> then(&"#{&1}-form")
  end
end
