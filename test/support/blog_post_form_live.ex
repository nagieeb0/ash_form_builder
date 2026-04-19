defmodule AshFormBuilder.Test.BlogPostFormLive do
  @moduledoc false
  use Phoenix.LiveView, layout: false

  alias AshFormBuilder.Test.Resources.BlogPost

  @impl true
  def mount(_params, _session, socket) do
    form =
      BlogPost.Form.for_create(authorize?: false)

    {:ok,
     assign(socket,
       form: form,
       resource: BlogPost
     )}
  end

  @impl true
  def handle_info({:form_submitted, resource, result}, socket) do
    {:noreply, assign(socket, last_submission: {resource, result})}
  end

  @impl true
  def handle_event("search_categories", _params, socket) do
    # In a real app, this would search categories and push events
    # For testing, we just return the socket unchanged
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div :if={Map.has_key?(assigns, :last_submission)} id="last-submission" class="last-submission" />
    <.live_component
      module={AshFormBuilder.FormComponent}
      id="blog-post-form-component"
      resource={@resource}
      form={@form}
      theme_opts={[
        target: @myself
      ]}
    />
    """
  end
end
