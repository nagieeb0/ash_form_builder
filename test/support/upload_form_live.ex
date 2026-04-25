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

    socket =
      socket
      |> assign(form: form, last_submission: nil)
      |> allow_upload(:avatar,
        accept: ~w(.jpg .jpeg .png),
        max_entries: 1,
        max_file_size: 5_000_000
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("validate", %{"form" => params}, socket) do
    form = AshPhoenix.Form.validate(socket.assigns.form.source, params)
    {:noreply, assign(socket, form: to_form(form))}
  end

  @impl true
  def handle_event("submit", %{"form" => form_params} = params, socket) do
    # Extract arguments from top-level params (AshPhoenix.Form pattern)
    # Arguments like "avatar" are passed at the top level, not inside "form"
    avatar_value = Map.get(params, "avatar")

    # Build submit params - merge form params with arguments
    submit_params = form_params

    # Add avatar argument if present
    submit_params =
      if avatar_value in [nil, "", []] do
        submit_params
      else
        Map.put(submit_params, "avatar", avatar_value)
      end

    # Submit the form
    case AshPhoenix.Form.submit(socket.assigns.form.source, params: submit_params) do
      {:ok, result} ->
        # Create a new form for the next submission
        new_form =
          UploadResources.UserProfile.Form.for_create(
            domain: UploadResources.Domain,
            authorize?: false
          )

        socket =
          socket
          |> assign(:form, to_form(new_form))
          |> assign(:last_submission, result)

        {:noreply, socket}

      {:error, form} ->
        {:noreply, assign(socket, form: to_form(form))}
    end
  end

  @impl true
  def handle_info({:form_submitted, _, result}, socket) do
    {:noreply, assign(socket, last_submission: result)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.form
      for={@form}
      id="user_profile-form"
      phx-change="validate"
      phx-submit="submit"
    >
      <div class="form-group">
        <label for="form_name">Full name</label>
        <input
          type="text"
          name="form[name]"
          id="form_name"
          value={Phoenix.HTML.Form.input_value(@form, :name)}
          class="form-input"
        />
      </div>

      <div class="form-group">
        <label for="avatar">Profile photo</label>
        <.live_file_input upload={@uploads.avatar} id="avatar-upload" />
        <p class="form-hint">JPEG or PNG, max 5 MB</p>

        <%= for entry <- @uploads.avatar.entries do %>
          <div class="upload-entry">
            <.live_img_preview entry={entry} />
            <span>{entry.client_name} - {entry.progress}%</span>
          </div>
        <% end %>

        <%= for err <- @uploads.avatar.errors do %>
          <p class="form-error">{upload_error_message(err)}</p>
        <% end %>
      </div>

      <button type="submit">Save profile</button>
    </.form>

    <div :if={@last_submission} id="upload-result">
      avatar_path: {@last_submission.avatar_path || "none"}
    </div>
    """
  end

  defp upload_error_message(:too_large), do: "File is too large"
  defp upload_error_message(:too_many_files), do: "Too many files selected"
  defp upload_error_message(:not_accepted), do: "File type not accepted"
  defp upload_error_message(err), do: "Upload error: #{err}"
end
