defmodule AshFormBuilder.FormRenderer do
  @moduledoc """
  Phoenix function components that render form entities.

  Structural rendering (entity iteration, nested `inputs_for` loops,
  add/remove buttons) lives here. Per-field widget rendering is
  delegated to a theme module.

  The theme is resolved in this order:

  1. The `:theme` assign passed to `form_fields/1` (preferred — set by
     `AshFormBuilder.FormComponent` from the per-form DSL).
  2. The `:ash_form_builder, :theme` Application config.
  3. `AshFormBuilder.Themes.Default`.
  """

  use Phoenix.Component

  alias Phoenix.LiveView.JS

  # ---------------------------------------------------------------------------
  # Public API
  # ---------------------------------------------------------------------------

  @doc """
  Renders all entities (fields and nested forms) for a form.

  Required assigns:
    * `:form`          — `Phoenix.HTML.Form`
    * `:entities`      — list of `Field` and `NestedForm` structs
    * `:target`        — LiveComponent target (`@myself`)
    * `:wrapper_class` — CSS class for the wrapper div

  Optional:
    * `:theme`      — theme module (overrides Application env)
    * `:theme_opts` — keyword list of theme-specific options (`:accent`,
       `:transitions`, etc.)
    * `:uploads`    — LiveView upload configs map
  """
  attr(:form, Phoenix.HTML.Form, required: true)
  attr(:entities, :list, required: true)
  attr(:target, :any, default: nil)
  attr(:wrapper_class, :string, default: "space-y-4")
  attr(:theme, :atom, default: nil)
  attr(:theme_opts, :list, default: [])
  attr(:uploads, :map, default: %{})

  def form_fields(assigns) do
    assigns = assign(assigns, :theme, assigns.theme || theme_module())

    ~H"""
    <div class={@wrapper_class}>
      <%= for entity <- @entities do %>
        <%= if is_struct(entity, AshFormBuilder.Field) do %>
          {@theme.render_field(
            %{form: @form, field: entity, target: @target, uploads: @uploads},
            @theme_opts
          )}
        <% end %>
        <%= if is_struct(entity, AshFormBuilder.NestedForm) do %>
          <.nested_form
            form={@form}
            nested={entity}
            target={@target}
            theme={@theme}
            theme_opts={@theme_opts}
          />
        <% end %>
      <% end %>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Nested form — structural rendering stays here
  # ---------------------------------------------------------------------------

  @doc "Renders a nested relationship form block with add/remove buttons."
  attr(:form, Phoenix.HTML.Form, required: true)
  attr(:nested, :any, required: true)
  attr(:target, :any, default: nil)
  attr(:theme, :atom, default: nil)
  attr(:theme_opts, :list, default: [])

  def nested_form(assigns) do
    theme = assigns.theme || theme_module()
    assigns = assign(assigns, :theme, theme)

    if function_exported?(theme, :render_nested, 1) do
      case theme.render_nested(assigns) do
        nil -> render_default_nested_form(assigns)
        rendered -> rendered
      end
    else
      render_default_nested_form(assigns)
    end
  end

  # ---------------------------------------------------------------------------
  # Default nested form rendering
  # ---------------------------------------------------------------------------

  defp render_default_nested_form(assigns) do
    accent = Keyword.get(assigns.theme_opts, :accent, :indigo)
    transitions = Keyword.get(assigns.theme_opts, :transitions, :subtle)

    current_count = nested_entry_count(assigns.form, assigns.nested)
    at_max? = !is_nil(assigns.nested.max_count) and current_count >= assigns.nested.max_count
    at_min? = current_count <= (assigns.nested.min_count || 0)

    assigns =
      assigns
      |> assign(:accent, accent)
      |> assign(:transitions, transitions)
      |> assign(:add_btn_class, nested_button_classes(accent, transitions, :primary))
      |> assign(:current_count, current_count)
      |> assign(:at_max?, at_max?)
      |> assign(:at_min?, at_min?)

    ~H"""
    <section class={[
      "mb-5 rounded-xl border border-gray-200 dark:border-gray-800",
      "bg-white dark:bg-gray-950 shadow-sm",
      @transitions != :none && "transition-shadow",
      @nested.class
    ]}>
      <header class="flex items-center justify-between gap-3 border-b border-gray-100 dark:border-gray-800/80 px-4 py-3">
        <div class="min-w-0 flex-1">
          <h3
            :if={@nested.label}
            class="text-sm font-semibold text-gray-800 dark:text-gray-100 truncate"
          >
            {@nested.label}
          </h3>
          <p class="text-[11px] uppercase tracking-wider font-medium text-gray-400 dark:text-gray-500 mt-0.5">
            {nested_count_label(@form, @nested)}
          </p>
        </div>
        <button
          :if={@nested.cardinality == :many}
          type="button"
          phx-click="add_form"
          phx-value-path={to_string(@nested.name)}
          phx-target={@target}
          disabled={@at_max?}
          aria-disabled={@at_max?}
          title={if(@at_max?, do: "Limit reached (max #{@nested.max_count})", else: nil)}
          class={[
            @add_btn_class,
            @at_max? && "opacity-50 cursor-not-allowed pointer-events-none"
          ]}
        >
          <svg
            class="h-3.5 w-3.5 mr-1 transition-transform group-hover:rotate-90"
            viewBox="0 0 20 20"
            fill="currentColor"
            aria-hidden="true"
          >
            <path d="M10 4a1 1 0 0 1 1 1v4h4a1 1 0 1 1 0 2h-4v4a1 1 0 1 1-2 0v-4H5a1 1 0 1 1 0-2h4V5a1 1 0 0 1 1-1z" />
          </svg>
          {@nested.add_label}
        </button>
      </header>

      <div class="divide-y divide-gray-100 dark:divide-gray-800/80">
        <.inputs_for :let={nested_f} field={@form[@nested.name]}>
          <div
            class="relative px-4 py-4 group/entry will-change-transform"
            phx-mounted={
              JS.transition(
                {"ease-out duration-300",
                 "opacity-0 -translate-y-1 scale-[0.98]",
                 "opacity-100 translate-y-0 scale-100"},
                time: 300
              )
            }
            phx-remove={
              JS.transition(
                {"ease-in duration-200",
                 "opacity-100 translate-y-0 scale-100",
                 "opacity-0 -translate-y-1 scale-[0.98]"},
                time: 200
              )
            }
          >
            <div :if={@nested.cardinality == :many} class="absolute right-3 top-3 z-10">
              <button
                type="button"
                phx-click="remove_form"
                phx-value-path={nested_f.name}
                phx-target={@target}
                disabled={@at_min?}
                aria-disabled={@at_min?}
                title={
                  if(@at_min?,
                    do: "Minimum #{@nested.min_count} required",
                    else: @nested.remove_label || "Remove"
                  )
                }
                aria-label={@nested.remove_label || "Remove"}
                class={[
                  remove_button_classes(@transitions),
                  @at_min? && "opacity-30 cursor-not-allowed pointer-events-none"
                ]}
              >
                <svg class="h-4 w-4" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                  <path d="M6.28 5.22a.75.75 0 0 0-1.06 1.06L8.94 10l-3.72 3.72a.75.75 0 1 0 1.06 1.06L10 11.06l3.72 3.72a.75.75 0 0 0 1.06-1.06L11.06 10l3.72-3.72a.75.75 0 0 0-1.06-1.06L10 8.94 6.28 5.22z" />
                </svg>
              </button>
            </div>
            <div class="pr-10">
              <%= for sub_entity <- nested_entities(@nested) do %>
                <%= if is_struct(sub_entity, AshFormBuilder.Field) do %>
                  {@theme.render_field(
                    %{form: nested_f, field: sub_entity, target: @target, uploads: %{}},
                    @theme_opts
                  )}
                <% end %>
                <%= if is_struct(sub_entity, AshFormBuilder.NestedForm) do %>
                  <.nested_form
                    form={nested_f}
                    nested={sub_entity}
                    target={@target}
                    theme={@theme}
                    theme_opts={@theme_opts}
                  />
                <% end %>
              <% end %>
            </div>
          </div>
        </.inputs_for>
      </div>

      <div
        :if={nested_empty?(@form, @nested)}
        class={[
          "flex flex-col items-center gap-1 px-4 py-8 text-center",
          "border-t border-dashed border-gray-200/60 dark:border-gray-800/60"
        ]}
      >
        <svg
          class="h-7 w-7 text-gray-300 dark:text-gray-700"
          fill="none"
          viewBox="0 0 24 24"
          stroke-width="1.5"
          stroke="currentColor"
          aria-hidden="true"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            d="M12 4.5v15m7.5-7.5h-15"
          />
        </svg>
        <p class="text-xs text-gray-500 dark:text-gray-400">
          No {String.downcase(@nested.label || to_string(@nested.name))} yet.
        </p>
      </div>
    </section>
    """
  end

  defp nested_empty?(form, nested) do
    case form[nested.name] do
      %Phoenix.HTML.FormField{value: value} ->
        value in [nil, [], %{}] or (is_list(value) and value == []) or
          (is_map(value) and map_size(value) == 0)

      _ ->
        true
    end
  end

  defp nested_count_label(form, nested) do
    count = nested_entry_count(form, nested)
    base = String.downcase(nested.label || to_string(nested.name))

    case {count, nested.max_count} do
      {_, nil} ->
        case count do
          0 -> "None added"
          1 -> "1 #{singularize(base)}"
          n -> "#{n} #{base}"
        end

      {n, max} ->
        "#{n} of #{max} #{if n == 1, do: singularize(base), else: base}"
    end
  end

  defp nested_entry_count(form, nested) do
    case form[nested.name] do
      %Phoenix.HTML.FormField{value: v} when is_list(v) -> length(v)
      %Phoenix.HTML.FormField{value: v} when is_map(v) -> map_size(v)
      _ -> 0
    end
  end

  defp singularize(word) do
    if String.ends_with?(word, "s") do
      String.slice(word, 0..-2//1)
    else
      word
    end
  end

  defp remove_button_classes(transitions) do
    base = [
      "inline-flex h-7 w-7 items-center justify-center rounded-full",
      "text-gray-400 hover:text-red-600 dark:text-gray-500 dark:hover:text-red-400",
      "hover:bg-red-50 dark:hover:bg-red-950/40",
      "opacity-60 group-hover/entry:opacity-100 focus-visible:opacity-100",
      "focus:outline-none focus-visible:ring-2 focus-visible:ring-red-500"
    ]

    motion =
      case transitions do
        :none -> []
        :subtle -> ["transition duration-150"]
        :smooth -> ["transition-all duration-200"]
      end

    Enum.join(base ++ motion, " ")
  end

  # `NestedForm.fields` is used by the DSL today, but to allow recursive
  # nesting we expose any nested entries declared inside it. Future DSL
  # work can store full entity structs here.
  defp nested_entities(%AshFormBuilder.NestedForm{fields: entities}) when is_list(entities),
    do: entities

  defp nested_entities(_), do: []

  defp nested_button_classes(accent, transitions, :primary) do
    base = [
      "group inline-flex items-center rounded-lg px-3 py-1.5 text-xs font-semibold",
      "text-#{accent}-700 dark:text-#{accent}-300",
      "bg-#{accent}-50 hover:bg-#{accent}-100 dark:bg-#{accent}-950/40 dark:hover:bg-#{accent}-900/40",
      "ring-1 ring-inset ring-#{accent}-200 dark:ring-#{accent}-800",
      "focus:outline-none focus-visible:ring-2 focus-visible:ring-#{accent}-500",
      "active:scale-[0.97]"
    ]

    motion = motion_classes(transitions)
    Enum.join(base ++ motion, " ")
  end

  defp motion_classes(:none), do: []
  defp motion_classes(:subtle), do: ["transition-colors duration-150"]
  defp motion_classes(:smooth), do: ["transition-all duration-200 hover:-translate-y-0.5"]

  # ---------------------------------------------------------------------------
  # Private
  # ---------------------------------------------------------------------------

  defp theme_module do
    case Application.get_env(:ash_form_builder, :theme) do
      nil -> AshFormBuilder.Themes.Default
      ref -> AshFormBuilder.Themes.resolve(ref)
    end
  end
end
