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

  ## File Upload Support

  Fields declared with `type: :file_upload` are automatically wired to Phoenix
  LiveView's upload lifecycle. Configure uploads via `opts`:

      field :avatar do
        type :file_upload
        opts [upload: [cloud: MyApp.Cloud, max_entries: 1, accept: ~w(.jpg .png)]]
      end

  On submit, entries are consumed and stored via the configured `Buckets.Cloud`
  module before the Ash action is called.
  """

  use Phoenix.LiveComponent

  alias AshFormBuilder.{FormRenderer, Info}

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    resource = assigns.resource
    action = assigns[:action] || extract_action(assigns.form)

    entities =
      resource
      |> Info.effective_entities(action)
      |> hydrate_relationship_options(assigns)

    submit_label = assigns[:submit_label] || Info.form_submit_label(resource, action)
    wrapper_class = Info.form_wrapper_class(resource, action)
    theme = assigns[:theme] || Info.form_theme(resource, action)
    accent = assigns[:accent] || Info.form_accent(resource, action)
    transitions = assigns[:transitions] || Info.form_transitions(resource, action)

    form_id =
      assigns[:form_id] || Info.form_html_id(resource, action) ||
        default_form_id(resource, action)

    socket =
      socket
      |> assign(assigns)
      |> assign(
        action: action,
        entities: entities,
        submit_label: submit_label,
        wrapper_class: wrapper_class,
        form_id: form_id,
        theme: theme,
        accent: accent,
        transitions: transitions
      )
      |> assign_new(:on_submit, fn -> nil end)

    # Allow file uploads after assigning form to socket
    socket = allow_file_uploads(socket, entities)

    {:ok, socket}
  end

  # ---------------------------------------------------------------------------
  # Auto-load options for relationship fields (many_to_many / belongs_to /
  # has_many) when the user did not supply them explicitly. Runs once per
  # `update/2` so fresh data is fetched whenever the parent re-assigns.
  # ---------------------------------------------------------------------------

  defp hydrate_relationship_options(entities, assigns) do
    actor = Map.get(assigns, :actor) || Map.get(assigns, :current_user)

    Enum.map(entities, fn
      %AshFormBuilder.Field{
        relationship_type: rel_type,
        destination_resource: dest,
        options: []
      } = field
      when rel_type in [:many_to_many, :has_many, :belongs_to] and not is_nil(dest) ->
        load_relationship_options(field, dest, actor)

      other ->
        other
    end)
  end

  defp load_relationship_options(field, destination, actor) do
    label_key = Keyword.get(field.opts || [], :label_key, :name)
    value_key = Keyword.get(field.opts || [], :value_key, :id)

    case safe_read(destination, actor) do
      {:ok, records} ->
        options =
          Enum.map(records, fn record ->
            label = Map.get(record, label_key) || to_string(Map.get(record, value_key))
            value = Map.get(record, value_key)
            {label, value}
          end)

        %{field | options: options}

      :error ->
        field
    end
  end

  defp safe_read(destination, actor) do
    case Ash.read(destination, actor: actor) do
      {:ok, records} -> {:ok, records}
      _ -> :error
    end
  rescue
    _ -> :error
  catch
    _, _ -> :error
  end

  defp extract_action(%Phoenix.HTML.Form{source: source}), do: extract_action(source)

  defp extract_action(%AshPhoenix.Form{source: source}), do: extract_action(source)

  defp extract_action(%{action: %{name: name}}) when is_atom(name), do: name
  defp extract_action(%{action: name}) when is_atom(name), do: name
  defp extract_action(_), do: nil

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div class="ash-form-builder">
      <.form
        for={@form}
        id={@form_id}
        phx-change="validate"
        phx-submit="submit"
        phx-target={@myself}
        class="space-y-6"
      >
        <div :if={top_level_errors(@form) != []} class="rounded-lg border border-red-200 bg-red-50 dark:border-red-900 dark:bg-red-950/40 p-3">
          <div class="flex items-start gap-2">
            <svg class="mt-0.5 h-4 w-4 shrink-0 text-red-500" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
              <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm-1-7V5a1 1 0 112 0v6a1 1 0 11-2 0zm1 4a1 1 0 110-2 1 1 0 010 2z" clip-rule="evenodd" />
            </svg>
            <div class="flex-1 text-xs">
              <p class="font-medium text-red-800 dark:text-red-200">Please fix the following:</p>
              <ul class="mt-1 list-disc pl-4 text-red-700 dark:text-red-300 space-y-0.5">
                <li :for={msg <- top_level_errors(@form)}>{msg}</li>
              </ul>
            </div>
          </div>
        </div>

        <FormRenderer.form_fields
          form={@form}
          entities={@entities}
          target={@myself}
          wrapper_class={@wrapper_class}
          theme={@theme}
          theme_opts={[
            target: @myself,
            accent: @accent,
            transitions: @transitions
          ]}
          uploads={Map.get(assigns, :uploads, %{})}
        />

        <div class="flex flex-col-reverse sm:flex-row sm:items-center sm:justify-end gap-3 pt-5 mt-2 border-t border-gray-100 dark:border-gray-800/80">
          <button
            type="submit"
            class={submit_button_classes(@accent, @transitions)}
            phx-disable-with="Saving…"
          >
            <span>{@submit_label}</span>
            <svg
              class="h-4 w-4"
              viewBox="0 0 20 20"
              fill="currentColor"
              aria-hidden="true"
            >
              <path
                fill-rule="evenodd"
                d="M10.293 4.293a1 1 0 011.414 0l5 5a1 1 0 010 1.414l-5 5a1 1 0 01-1.414-1.414L13.586 11H4a1 1 0 110-2h9.586l-3.293-3.293a1 1 0 010-1.414z"
                clip-rule="evenodd"
              />
            </svg>
          </button>
        </div>
      </.form>
    </div>
    """
  end

  defp top_level_errors(form) do
    case form.source do
      %AshPhoenix.Form{submit_errors: errs} when is_list(errs) and errs != [] ->
        Enum.flat_map(errs, fn
          %{message: msg} when is_binary(msg) -> [msg]
          {msg, _opts} when is_binary(msg) -> [msg]
          msg when is_binary(msg) -> [msg]
          _ -> []
        end)

      _ ->
        []
    end
  end

  # ---------------------------------------------------------------------------
  # Events
  # ---------------------------------------------------------------------------

  @impl Phoenix.LiveComponent
  def handle_event("validate", %{"form" => params}, socket) do
    form = AshPhoenix.Form.validate(socket.assigns.form.source, sanitize_form_params(params))
    {:noreply, assign(socket, form: to_form(form))}
  end

  def handle_event("validate", _params, socket), do: {:noreply, socket}

  @impl Phoenix.LiveComponent
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    socket =
      socket.assigns
      |> Map.get(:uploads, %{})
      |> Map.keys()
      |> Enum.reduce(socket, fn upload_name, acc ->
        Phoenix.LiveView.cancel_upload(acc, upload_name, ref)
      end)

    {:noreply, socket}
  end

  @impl Phoenix.LiveComponent
  def handle_event("toggle_file_delete", %{"field" => field}, socket) do
    # Get current delete state
    form = socket.assigns.form.source
    current_delete_value = Phoenix.HTML.Form.input_value(form, "#{field}_delete")

    # Toggle the delete flag
    new_delete_value = if current_delete_value == "true", do: "false", else: "true"

    # Update form with new delete flag value
    params = %{"#{field}_delete" => new_delete_value}
    form = AshPhoenix.Form.validate(form, params)

    {:noreply, assign(socket, form: to_form(form))}
  end

  @impl Phoenix.LiveComponent
  def handle_event("add_form", %{"path" => path}, socket) do
    # AshPhoenix.Form accepts the raw string path verbatim — no parsing needed.
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
    form = socket.assigns.form.source
    current_values = AshPhoenix.Form.value(form, String.to_existing_atom(field)) || []
    new_values = Enum.reject(current_values, &(to_string(&1) == item))
    form = AshPhoenix.Form.validate(form, %{field => new_values})
    {:noreply, assign(socket, form: to_form(form))}
  end

  @impl Phoenix.LiveComponent
  def handle_event(
        "create_combobox_item",
        %{
          "field" => field,
          "resource" => resource_mod,
          "action" => action,
          "creatable_value" => creatable_value
        },
        socket
      ) do
    resource_mod = String.to_existing_atom(resource_mod)
    field = String.to_existing_atom(field)
    action = String.to_existing_atom(action)

    new_item_value = extract_creatable_value(creatable_value)

    case create_new_item(resource_mod, action, new_item_value, socket.assigns) do
      {:ok, new_record} ->
        form = socket.assigns.form.source
        current_values = AshPhoenix.Form.value(form, field) || []
        new_id = Map.get(new_record, :id)
        primary_attr = determine_primary_attr(resource_mod)
        new_label = new_record |> Map.get(primary_attr) |> to_string()

        updated_values =
          current_values
          |> List.wrap()
          |> Enum.reject(&(&1 in [nil, ""]))
          |> Kernel.++([new_id])
          |> Enum.uniq()

        form = AshPhoenix.Form.validate(form, %{field => updated_values})

        {:noreply,
         socket
         |> assign(form: to_form(form))
         |> push_event("ash_form_combobox_pill_added", %{
           field: to_string(field),
           id: to_string(new_id),
           label: new_label
         })}

      {:error, changeset_or_error} ->
        require Logger
        Logger.error("Failed to create combobox item: #{inspect(changeset_or_error)}")
        {:noreply, put_flash(socket, :error, "Could not create item: validation failed")}
    end
  end

  @impl Phoenix.LiveComponent
  def handle_event("submit", %{"form" => params}, socket) do
    entities = socket.assigns.entities
    file_fields = extract_file_upload_fields(entities)

    # Consume all file uploads before submitting to Ash
    {upload_params, socket} = consume_file_uploads(socket, file_fields, params)

    merged_params =
      params
      |> Map.merge(upload_params)
      |> sanitize_form_params()

    case AshPhoenix.Form.submit(socket.assigns.form.source, params: merged_params) do
      {:ok, result} ->
        notify_parent(socket, result)
        {:noreply, socket}

      {:error, form} ->
        {:noreply, assign(socket, form: to_form(form))}
    end
  end

  # Strip empty-string placeholders from list-valued params so that
  # `tags: [""]` becomes `tags: []`. Multiselect renders a hidden
  # `<input value="">` so the form always sends *something* for the field
  # even when no pills are selected — but that empty placeholder would
  # otherwise reach Ash as a nil-array element and trigger
  # `no nil values`.
  defp sanitize_form_params(params) when is_map(params) do
    Map.new(params, fn {k, v} -> {k, sanitize_form_value(v)} end)
  end

  defp sanitize_form_params(params), do: params

  defp sanitize_form_value(value) when is_list(value) do
    value
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.map(&sanitize_form_value/1)
  end

  defp sanitize_form_value(value) when is_map(value), do: sanitize_form_params(value)
  defp sanitize_form_value(value), do: value

  # ---------------------------------------------------------------------------
  # File Upload Lifecycle
  # ---------------------------------------------------------------------------

  defp allow_file_uploads(socket, entities) do
    entities
    |> extract_file_upload_fields()
    |> Enum.reduce(socket, fn field, socket ->
      if upload_registered?(socket, field.name) do
        socket
      else
        Phoenix.LiveView.allow_upload(socket, field.name, build_allow_upload_opts(field))
      end
    end)
  end

  defp upload_registered?(socket, name) do
    socket.assigns
    |> Map.get(:uploads, %{})
    |> Map.has_key?(name)
  end

  defp build_allow_upload_opts(field) do
    legacy = Keyword.get(field.opts, :upload, [])

    accept =
      cond do
        not is_nil(field.accept) -> normalize_accept(field.accept)
        true -> normalize_accept(Keyword.get(legacy, :accept, :any))
      end

    max_entries = field.max_files || Keyword.get(legacy, :max_entries, 1)

    max_file_size =
      normalize_size(field.max_file_size || Keyword.get(legacy, :max_file_size, 8_000_000))

    base = [accept: accept, max_entries: max_entries, max_file_size: max_file_size]

    if field.auto_upload, do: Keyword.put(base, :auto_upload, true), else: base
  end

  defp normalize_accept(:any), do: :any
  defp normalize_accept(:images), do: ~w(.jpg .jpeg .png .gif .webp .svg)
  defp normalize_accept(:documents), do: ~w(.pdf .doc .docx .txt .md .rtf)
  defp normalize_accept(:audio), do: ~w(.mp3 .wav .ogg .m4a .flac)
  defp normalize_accept(:video), do: ~w(.mp4 .mov .webm .avi .mkv)
  defp normalize_accept(value) when is_list(value), do: value
  defp normalize_accept(value) when is_binary(value), do: [value]
  defp normalize_accept(_), do: :any

  defp normalize_size(n) when is_integer(n), do: n
  defp normalize_size({n, :kb}) when is_integer(n), do: n * 1_000
  defp normalize_size({n, :mb}) when is_integer(n), do: n * 1_000_000
  defp normalize_size({n, :gb}) when is_integer(n), do: n * 1_000_000_000
  defp normalize_size(_), do: 8_000_000

  defp consume_file_uploads(socket, file_fields, params) do
    Enum.reduce(file_fields, {%{}, socket}, fn field, {acc_params, socket} ->
      upload_config =
        field.opts
        |> Keyword.get(:upload, [])
        |> Keyword.merge(
          Enum.reject(
            [
              cloud: field.cloud,
              bucket_name: field.bucket
            ],
            fn {_, v} -> is_nil(v) end
          )
        )

      cloud_module = resolve_cloud_module(upload_config)

      # Auto-detect target attribute name from field name
      target_attribute = detect_target_attribute(field.name, upload_config)

      # Check if user wants to delete existing file
      delete_flag = Map.get(params, "#{field.name}_delete") == "true"

      # Get existing file path before deletion
      existing_path = get_existing_file_path(socket.assigns.form, field.name)

      # Consume uploaded entries and store files (if not deleting)
      result =
        if delete_flag do
          []
        else
          Phoenix.LiveView.consume_uploaded_entries(
            socket,
            field.name,
            &store_upload_entry(&1, &2, cloud_module, upload_config)
          )
        end

      # Filter out postponed entries (errors)
      successful_paths = Enum.filter(result, &(elem(&1, 0) == :ok))

      # Log errors
      Enum.each(result, fn
        {:postpone, reason} ->
          require Logger
          Logger.error("File upload postponed: #{inspect(reason)}")

        _ ->
          :ok
      end)

      # Build params from successful uploads or deletion
      upload_params =
        cond do
          # User requested deletion
          delete_flag and not is_nil(existing_path) ->
            # Cascade delete from storage
            cascade_delete_file(existing_path, cloud_module, upload_config)
            %{to_string(target_attribute) => nil}

          # New file uploaded (single)
          match?([{:ok, _}], successful_paths) and length(successful_paths) == 1 ->
            [{:ok, path}] = successful_paths
            %{to_string(target_attribute) => path}

          # Multiple files uploaded
          length(successful_paths) > 1 ->
            paths = Enum.map(successful_paths, &elem(&1, 1))
            %{to_string(target_attribute) => paths}

          # No new upload, keep existing (don't override)
          true ->
            %{}
        end

      {Map.merge(acc_params, upload_params), socket}
    end)
  end

  defp cascade_delete_file(path, cloud_module, upload_config) when is_binary(path) do
    # Delete single file
    delete_file_from_storage(path, cloud_module, upload_config)
  end

  defp cascade_delete_file(paths, cloud_module, upload_config) when is_list(paths) do
    # Delete multiple files
    Enum.each(paths, &delete_file_from_storage(&1, cloud_module, upload_config))
  end

  defp cascade_delete_file(nil, _cloud_module, _upload_config), do: :ok

  defp delete_file_from_storage(path, cloud_module, upload_config) when is_binary(path) do
    if is_nil(cloud_module) do
      require Logger
      Logger.info("File marked for deletion (no cloud module): #{path}")
      :ok
    else
      object = %Buckets.Object{
        uuid: generate_uuid_from_path(path),
        filename: Path.basename(path),
        location: %Buckets.Location{
          path: path,
          config: upload_config
        },
        data: nil,
        metadata: %{},
        stored?: true
      }

      case cloud_module.delete(object) do
        {:ok, _} ->
          require Logger
          Logger.info("File deleted from storage: #{path}")
          :ok

        {:error, reason} ->
          require Logger
          Logger.error("Failed to delete file from storage: #{path} - #{inspect(reason)}")
          :error
      end
    end
  end

  defp generate_uuid_from_path(path) do
    # Generate a UUID-like identifier from the path
    :crypto.hash(:md5, path) |> Base.encode16(case: :lower)
  end

  defp get_existing_file_path(form, field_name) do
    case Phoenix.HTML.Form.input_value(form, field_name) do
      nil -> nil
      "" -> nil
      value -> value
    end
  end

  defp detect_target_attribute(field_name, upload_config) do
    # Check for explicit target_attribute in config
    case Keyword.get(upload_config, :target_attribute) do
      nil ->
        # Auto-detect: append _path to field name
        # e.g., :proposal → :proposal_path, :avatar → :avatar_path
        String.to_existing_atom("#{field_name}_path")

      target ->
        target
    end
  end

  defp store_upload_entry(%{path: _path} = meta, entry, cloud_module, upload_config)
       when not is_nil(cloud_module) do
    object = Buckets.Object.from_upload({entry, meta})

    # Get bucket_name from config if provided
    bucket_name = Keyword.get(upload_config, :bucket_name)
    insert_opts = if bucket_name, do: [bucket_name: bucket_name], else: []

    case cloud_module.insert(object, insert_opts) do
      {:ok, stored} ->
        # Return path
        {:ok, stored.location.path}

      {:error, reason} ->
        require Logger
        Logger.error("Upload storage failed for #{entry.client_name}: #{inspect(reason)}")
        {:postpone, reason}
    end
  end

  defp store_upload_entry(%{path: temp_path}, _entry, _cloud_module, _upload_config) do
    # No cloud module configured, return temp path
    {:ok, temp_path}
  end

  defp resolve_cloud_module(upload_config) do
    Keyword.get(upload_config, :cloud) ||
      Application.get_env(:ash_form_builder, :upload_cloud)
  end

  defp extract_file_upload_fields(entities) do
    Enum.flat_map(entities, fn
      %AshFormBuilder.Field{type: :file_upload} = field -> [field]
      _ -> []
    end)
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

  @doc false
  def parse_nested_path(path_string) do
    # Handle paths like:
    # - "subtasks" (simple nested form)
    # - "subtasks[0]" (indexed nested form)
    # - "form[subtasks]" (Phoenix.HTML.Form wrapped)
    # - "form[subtasks][0]" (Phoenix.HTML.Form wrapped with index)
    # - "level1[0].level2[1]" (deeply nested)

    # First, strip "form[" prefix if present
    path_string =
      if String.starts_with?(path_string, "form[") do
        # Remove "form[" prefix
        path_string = String.replace_prefix(path_string, "form[", "")
        # Remove trailing "]" to match the opening "form["
        # But be careful not to remove "]" that's part of an index like "[0]"
        # The pattern is "form[field][index]" or "form[field]"
        # After removing "form[", we have "field][index]" or "field]"
        # We need to remove only the LAST "]" that closes the "form["
        String.replace_suffix(path_string, "]", "")
      else
        path_string
      end

    # Now split by "." for multi-level nesting
    segments = String.split(path_string, ".")
    Enum.map(segments, &parse_path_segment/1)
  end

  defp parse_path_segment(segment) do
    # Handle paths like "subtasks[0]" or "field[]" or just "field"
    # Also handle malformed paths like "subtasks][0" from "form[subtasks][0]"
    cond do
      # Handle "subtasks][0" or "subtasks][0]" format (from "form[subtasks][0]")
      match = Regex.run(~r/^(\w+)\]\[(\d+)\]?$/, segment) ->
        [_, field, index] = match
        {String.to_existing_atom(field), String.to_integer(index)}

      # Empty brackets like field[]
      Regex.match?(~r/\[\]$/, segment) ->
        field = Regex.replace(~r/\[\]$/, segment, "")
        String.to_existing_atom(field)

      # Indexed brackets like field[0]
      match = Regex.run(~r/^(\w+)\[(\d+)\]$/, segment) ->
        [_, field, index] = match
        {String.to_existing_atom(field), String.to_integer(index)}

      # Plain field name
      true ->
        String.to_existing_atom(segment)
    end
  end

  defp create_new_item(resource_mod, action, value, assigns) do
    actor = Map.get(assigns, :actor)
    primary_attr = determine_primary_attr(resource_mod)
    input_params = %{primary_attr => value}
    domain = get_domain_for_resource(resource_mod)

    create_opts =
      [actor: actor]
      |> then(fn opts -> if domain, do: Keyword.put(opts, :domain, domain), else: opts end)

    resource_mod
    |> Ash.Changeset.for_create(action, input_params, create_opts)
    |> Ash.create(create_opts)
  end

  defp extract_creatable_value(label) do
    case Regex.run(~r/Create "([^"]+)"/, label) do
      [_, value] -> value
      _ -> label
    end
  end

  defp determine_primary_attr(resource_mod) do
    cond do
      Ash.Resource.Info.attribute(resource_mod, :name) ->
        :name

      Ash.Resource.Info.attribute(resource_mod, :title) ->
        :title

      Ash.Resource.Info.attribute(resource_mod, :label) ->
        :label

      Ash.Resource.Info.attribute(resource_mod, :value) ->
        :value

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
    case Spark.Dsl.Extension.get_persisted(resource_mod, :domain) do
      nil ->
        module_parts = Module.split(resource_mod)

        with [_, _ | _] <- module_parts,
             domain_parts = Enum.drop(module_parts, -1),
             domain_mod = Module.concat(domain_parts),
             true <- Code.ensure_loaded?(domain_mod),
             true <- function_exported?(domain_mod, :__ash_domain__, 0) do
          domain_mod
        else
          _ -> nil
        end

      domain ->
        domain
    end
  end

  defp default_form_id(resource, action) do
    base =
      resource
      |> Module.split()
      |> List.last()
      |> Macro.underscore()

    if action, do: "#{base}-#{action}-form", else: "#{base}-form"
  end

  @doc false
  def submit_button_classes(accent, transitions) do
    base = [
      "inline-flex w-full sm:w-auto items-center justify-center gap-2 rounded-xl",
      "px-6 py-3 sm:px-5 sm:py-2.5",
      "text-base sm:text-sm font-semibold text-white shadow-sm",
      "focus:outline-none focus-visible:ring-2 focus-visible:ring-offset-2",
      "disabled:opacity-60 disabled:cursor-not-allowed",
      "active:scale-[0.98]"
    ]

    color = [
      "bg-#{accent}-600 hover:bg-#{accent}-700",
      "focus-visible:ring-#{accent}-500",
      "shadow-#{accent}-600/20"
    ]

    motion =
      case transitions do
        :none -> []
        :subtle -> ["transition duration-150"]
        :smooth -> ["transition-all duration-200 hover:-translate-y-0.5 hover:shadow-md"]
      end

    Enum.join(base ++ color ++ motion, " ")
  end
end
