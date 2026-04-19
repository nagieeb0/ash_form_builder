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
  def handle_event("remove_combobox_item", %{"field" => field, "item" => item}, socket) do
    # Remove a selected item from a combobox field
    form = socket.assigns.form.source
    current_values = AshPhoenix.Form.value(form, field) || []
    new_values = Enum.reject(current_values, &to_string(&1) == item)
    form = AshPhoenix.Form.validate(form, %{field => new_values})
    {:noreply, assign(socket, form: to_form(form))}
  end

  @impl Phoenix.LiveComponent
  def handle_event(
        "create_combobox_item",
        %{"field" => field, "resource" => resource_mod, "action" => action, "creatable_value" => creatable_value},
        socket
      ) do
    # Create a new record in the destination resource and add it to the selection
    resource_mod = String.to_atom(resource_mod)
    field = String.to_atom(field)
    action = String.to_atom(action)

    # The creatable_value contains the label like "Create \"New Tag\""
    # We need to extract the actual value from the quoted string
    new_item_value = extract_creatable_value(creatable_value)

    # Create the new record using Ash
    case create_new_item(resource_mod, action, new_item_value, socket.assigns) do
      {:ok, new_record} ->
        # Add the new record to the current selection
        form = socket.assigns.form.source
        current_values = AshPhoenix.Form.value(form, field) || []
        new_id = Map.get(new_record, :id)
        updated_values = Enum.uniq(current_values ++ [new_id])
        form = AshPhoenix.Form.validate(form, %{field => updated_values})
        {:noreply, assign(socket, form: to_form(form))}

      {:error, changeset_or_error} ->
        # Log the error and return the form unchanged
        # In production, you might want to show a toast or inline error
        require Logger
        Logger.error("Failed to create combobox item: #{inspect(changeset_or_error)}")
        {:noreply, socket}
    end
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

  defp create_new_item(resource_mod, action, value, assigns) do
    # Extract actor from assigns for authorization
    actor = Map.get(assigns, :actor)

    # Determine the primary attribute name for the resource
    # Try common patterns: :name, :title, :label
    primary_attr = determine_primary_attr(resource_mod)

    # Build the input params for creating the new item
    input_params = %{primary_attr => value}

    # Use Ash Domain's code interface if available, otherwise direct resource call
    # This respects all Ash policies and validations automatically
    domain = get_domain_for_resource(resource_mod)

    cond do
      # Try to use domain if available
      not is_nil(domain) and function_exported?(domain, action, 2) ->
        apply(domain, action, [input_params, [actor: actor]])

      # Fall back to direct Ash resource call
      function_exported?(resource_mod, action, 2) ->
        apply(resource_mod, action, [input_params, [actor: actor]])

      # Try Ash.create/2 as a last resort
      true ->
        struct(resource_mod, input_params)
        |> Ash.create(actor: actor)
    end
  end

  defp extract_creatable_value(label) do
    # Extract value from label like "Create \"New Tag\""
    # The pattern is: Create "value"
    case Regex.run(~r/Create "([^"]+)"/, label) do
      [_, value] -> value
      _ -> label
    end
  end

  defp determine_primary_attr(resource_mod) do
    # Check for common primary attribute names in order of preference
    cond do
      Ash.Resource.Info.attribute(resource_mod, :name) -> :name
      Ash.Resource.Info.attribute(resource_mod, :title) -> :title
      Ash.Resource.Info.attribute(resource_mod, :label) -> :label
      Ash.Resource.Info.attribute(resource_mod, :value) -> :value
      # Fall back to the first string attribute
      true ->
        resource_mod
        |> Ash.Resource.Info.attributes()
        |> Enum.find(:name, fn attr ->
          attr.type in [:string, :ci_string] and attr.name != :id
        end)
        |> case do
          %Ash.Resource.Attribute{name: name} -> name
          _ -> :name
        end
    end
  end

  defp get_domain_for_resource(resource_mod) do
    # Try to get the domain from the resource's __ash_resource__ config
    case Spark.Dsl.Extension.get_persisted(resource_mod, :domain) do
      nil ->
        # Try to infer from module name (e.g., MyApp.Billing.Clinic -> MyApp.Billing)
        module_parts = Module.split(resource_mod)

        if length(module_parts) >= 2 do
          domain_parts = Enum.drop(module_parts, -1)
          domain_mod = Module.concat(domain_parts)

          # Verify the domain module exists and is an Ash domain
          if Code.ensure_loaded?(domain_mod) and
               function_exported?(domain_mod, :__ash_domain__, 0) do
            domain_mod
          else
            nil
          end
        else
          nil
        end

      domain ->
        domain
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
