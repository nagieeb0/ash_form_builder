defmodule AshFormBuilder.Test.ClinicFormLive do
  @moduledoc false
  use Phoenix.LiveView, layout: false

  @impl true
  def mount(_params, _session, socket) do
    form =
      AshFormBuilder.Test.Domain.Clinic.Form.for_create(
        domain: AshFormBuilder.Test.Domain,
        authorize?: false
      )

    {:ok,
     assign(socket,
       form: form,
       resource: AshFormBuilder.Test.Domain.Clinic,
       last_submission: nil
     )}
  end

  @impl true
  def handle_info({:form_submitted, resource, result}, socket) do
    {:noreply, assign(socket, last_submission: {resource, result})}
  end

  @impl true
  def handle_event("search_specialties", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div :if={@last_submission} id="last-submission" class="last-submission" />
    <.live_component
      module={AshFormBuilder.FormComponent}
      id="clinic-form-component"
      resource={@resource}
      form={@form}
    />
    """
  end
end
