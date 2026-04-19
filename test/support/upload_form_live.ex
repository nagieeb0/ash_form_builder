defmodule AshFormBuilder.Test.UploadFormLive do
  @moduledoc false
  use Phoenix.LiveView, layout: false

  alias AshFormBuilder.Test.UploadResources

  @impl true
  def mount(_params, _session, socket) do
    form =
      UploadResources.UserProfile.Form.for_create(
        domain: UploadResources.Domain,
        authorize?: false
      )

    {:ok, assign(socket, form: form, last_submission: nil)}
  end

  @impl true
  def handle_info({:form_submitted, _, result}, socket) do
    {:noreply, assign(socket, last_submission: result)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.live_component
      module={AshFormBuilder.FormComponent}
      id="upload-form-component"
      resource={AshFormBuilder.Test.UploadResources.UserProfile}
      form={@form}
    />

    <div :if={@last_submission} id="upload-result">
      avatar_path: {@last_submission.avatar_path || "none"}
    </div>
    """
  end
end
