defmodule MishkaChelekom.Components.Combobox do
  @moduledoc """
  Stub module for MishkaChelekom Combobox component.

  Generate the real component in your host application using:

      mix mishka.ui.gen.component combobox

  These stubs render plain (but functional) HTML so forms still work
  end-to-end when the upstream component library is not installed.
  """

  use Phoenix.Component

  attr(:field, Phoenix.HTML.FormField, default: nil)
  attr(:name, :string, default: nil)
  attr(:label, :string, default: nil)
  attr(:value, :any, default: nil)
  attr(:options, :list, default: [])
  attr(:required, :boolean, default: false)
  attr(:errors, :list, default: [])
  attr(:multiple, :boolean, default: false)
  attr(:color, :string, default: nil)
  attr(:variant, :string, default: nil)
  attr(:rest, :global)
  slot(:trigger)
  slot(:inner_block)

  def combobox(assigns) do
    name =
      cond do
        assigns.name -> assigns.name
        assigns.field && assigns.multiple -> assigns.field.name <> "[]"
        assigns.field -> assigns.field.name
        true -> nil
      end

    selected =
      cond do
        not is_nil(assigns.value) -> List.wrap(assigns.value)
        assigns.field -> List.wrap(assigns.field.value)
        true -> []
      end

    selected_strs = Enum.map(selected, &to_string/1)
    assigns = assign(assigns, name: name, selected: selected, selected_strs: selected_strs)

    ~H"""
    <div class={["mishka-combobox-stub", @multiple && "mishka-combobox-multiple"]}>
      <label :if={@label} class="block text-sm font-medium mb-1">
        {@label}<span :if={@required} class="text-red-500"> *</span>
      </label>
      <select
        :if={@multiple}
        name={@name}
        multiple
        required={@required}
        class="w-full border rounded px-3 py-2"
      >
        <option
          :for={{lbl, val} <- normalize_combobox_options(@options)}
          value={val}
          selected={to_string(val) in @selected_strs}
        >
          {lbl}
        </option>
      </select>
      <select
        :if={not @multiple}
        name={@name}
        required={@required}
        class="w-full border rounded px-3 py-2"
      >
        <option
          :for={{lbl, val} <- normalize_combobox_options(@options)}
          value={val}
          selected={to_string(val) in @selected_strs}
        >
          {lbl}
        </option>
      </select>
      <p :for={{msg, _} <- @errors} class="text-xs text-red-600 mt-1">{msg}</p>
      {render_slot(@trigger, @selected)}
      {render_slot(@inner_block)}
    </div>
    """
  end

  defp normalize_combobox_options(options) do
    Enum.map(options, fn
      {label, value} -> {label, value}
      value when is_atom(value) -> {Phoenix.Naming.humanize(value), value}
      value -> {to_string(value), value}
    end)
  end

  attr(:field, Phoenix.HTML.FormField, default: nil)
  attr(:placeholder, :string, default: nil)
  attr(:rest, :global)

  def combobox_input(assigns) do
    ~H"""
    <input
      type="text"
      id={@field && @field.id}
      name={@field && @field.name}
      value={@field && Phoenix.HTML.Form.normalize_value("text", @field.value)}
      placeholder={@placeholder}
      class="mishka-combobox-input-stub border rounded px-3 py-2 w-full"
      {@rest}
    />
    """
  end

  slot(:inner_block)
  slot(:create_action)

  def combobox_options(assigns) do
    ~H"""
    <div class="mishka-combobox-options-stub">
      {render_slot(@inner_block)}
      {render_slot(@create_action)}
    </div>
    """
  end

  attr(:value, :any, default: nil)
  attr(:selected, :boolean, default: false)
  attr(:rest, :global)
  slot(:inner_block)

  def combobox_option(assigns) do
    ~H"""
    <div
      class={["mishka-combobox-option-stub", @selected && "is-selected"]}
      data-value={@value && to_string(@value)}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end
end

defmodule MishkaChelekom.Components.TextField do
  @moduledoc """
  Functional fallback for MishkaChelekom TextField. Renders a real
  `<label>` + `<input>` bound to the given form field. Generate the
  styled component with `mix mishka.ui.gen.component text_field` to
  override.
  """

  use Phoenix.Component

  attr(:field, Phoenix.HTML.FormField, required: true)
  attr(:label, :string, default: nil)
  attr(:placeholder, :string, default: nil)
  attr(:required, :boolean, default: false)
  attr(:hint, :string, default: nil)
  attr(:errors, :list, default: [])
  attr(:class, :string, default: nil)
  attr(:wrapper_class, :string, default: nil)
  attr(:type, :string, default: "text")
  attr(:color, :string, default: nil)
  attr(:variant, :string, default: nil)
  attr(:rest, :global, include: ~w(autocomplete disabled readonly maxlength minlength pattern))

  def text_field(assigns) do
    ~H"""
    <div class={["mishka-textfield-stub", @wrapper_class]}>
      <label :if={@label} for={@field.id} class="block text-sm font-medium mb-1">
        {@label}<span :if={@required} class="text-red-500"> *</span>
      </label>
      <input
        type={@type}
        id={@field.id}
        name={@field.name}
        value={Phoenix.HTML.Form.normalize_value(@type, @field.value)}
        placeholder={@placeholder}
        required={@required}
        class={["w-full border rounded px-3 py-2", @class]}
        {@rest}
      />
      <p :if={@hint} class="text-xs text-gray-500 mt-1">{@hint}</p>
      <p :for={{msg, _} <- @errors} class="text-xs text-red-600 mt-1">{msg}</p>
    </div>
    """
  end
end

defmodule MishkaChelekom.Components.TextareaField do
  @moduledoc """
  Functional fallback for MishkaChelekom TextareaField. Generate with
  `mix mishka.ui.gen.component textarea_field` to override.
  """

  use Phoenix.Component

  attr(:field, Phoenix.HTML.FormField, required: true)
  attr(:label, :string, default: nil)
  attr(:placeholder, :string, default: nil)
  attr(:required, :boolean, default: false)
  attr(:hint, :string, default: nil)
  attr(:errors, :list, default: [])
  attr(:class, :string, default: nil)
  attr(:wrapper_class, :string, default: nil)
  attr(:rows, :any, default: 3)
  attr(:color, :string, default: nil)
  attr(:variant, :string, default: nil)
  attr(:rest, :global)

  def textarea_field(assigns) do
    ~H"""
    <div class={["mishka-textareafield-stub", @wrapper_class]}>
      <label :if={@label} for={@field.id} class="block text-sm font-medium mb-1">
        {@label}<span :if={@required} class="text-red-500"> *</span>
      </label>
      <textarea
        id={@field.id}
        name={@field.name}
        placeholder={@placeholder}
        required={@required}
        rows={@rows}
        class={["w-full border rounded px-3 py-2", @class]}
        {@rest}
      >{Phoenix.HTML.Form.normalize_value("textarea", @field.value)}</textarea>
      <p :if={@hint} class="text-xs text-gray-500 mt-1">{@hint}</p>
      <p :for={{msg, _} <- @errors} class="text-xs text-red-600 mt-1">{msg}</p>
    </div>
    """
  end
end

defmodule MishkaChelekom.Components.NativeSelect do
  @moduledoc """
  Functional fallback for MishkaChelekom NativeSelect. Generate with
  `mix mishka.ui.gen.component native_select` to override.
  """

  use Phoenix.Component

  attr(:field, Phoenix.HTML.FormField, required: true)
  attr(:label, :string, default: nil)
  attr(:options, :list, default: [])
  attr(:prompt, :string, default: nil)
  attr(:required, :boolean, default: false)
  attr(:hint, :string, default: nil)
  attr(:errors, :list, default: [])
  attr(:class, :string, default: nil)
  attr(:wrapper_class, :string, default: nil)
  attr(:color, :string, default: nil)
  attr(:variant, :string, default: nil)
  attr(:rest, :global)

  def native_select(assigns) do
    ~H"""
    <div class={["mishka-nativeselect-stub", @wrapper_class]}>
      <label :if={@label} for={@field.id} class="block text-sm font-medium mb-1">
        {@label}<span :if={@required} class="text-red-500"> *</span>
      </label>
      <select
        id={@field.id}
        name={@field.name}
        required={@required}
        class={["w-full border rounded px-3 py-2", @class]}
        {@rest}
      >
        {Phoenix.HTML.Form.options_for_select(@options, @field.value)}
      </select>
      <p :if={@hint} class="text-xs text-gray-500 mt-1">{@hint}</p>
      <p :for={{msg, _} <- @errors} class="text-xs text-red-600 mt-1">{msg}</p>
    </div>
    """
  end
end

defmodule MishkaChelekom.Components.CheckboxField do
  @moduledoc """
  Functional fallback for MishkaChelekom CheckboxField. Generate with
  `mix mishka.ui.gen.component checkbox_field` to override.
  """

  use Phoenix.Component

  attr(:field, Phoenix.HTML.FormField, required: true)
  attr(:label, :string, default: nil)
  attr(:hint, :string, default: nil)
  attr(:errors, :list, default: [])
  attr(:class, :string, default: nil)
  attr(:wrapper_class, :string, default: nil)
  attr(:required, :boolean, default: false)
  attr(:color, :string, default: nil)
  attr(:variant, :string, default: nil)
  attr(:rest, :global)

  def checkbox_field(assigns) do
    checked? = assigns.field.value in [true, "true", "on", "1", 1]
    assigns = assign(assigns, :checked, checked?)

    ~H"""
    <div class={["mishka-checkboxfield-stub flex items-center gap-2", @wrapper_class]}>
      <input type="hidden" name={@field.name} value="false" />
      <input
        type="checkbox"
        id={@field.id}
        name={@field.name}
        value="true"
        checked={@checked}
        class={@class}
        {@rest}
      />
      <label :if={@label} for={@field.id} class="text-sm">{@label}</label>
      <p :if={@hint} class="text-xs text-gray-500 mt-1">{@hint}</p>
      <p :for={{msg, _} <- @errors} class="text-xs text-red-600 mt-1">{msg}</p>
    </div>
    """
  end
end

defmodule MishkaChelekom.Components.NumberField do
  @moduledoc """
  Functional fallback for MishkaChelekom NumberField. Generate with
  `mix mishka.ui.gen.component number_field` to override.
  """

  use Phoenix.Component

  attr(:field, Phoenix.HTML.FormField, required: true)
  attr(:label, :string, default: nil)
  attr(:placeholder, :string, default: nil)
  attr(:required, :boolean, default: false)
  attr(:hint, :string, default: nil)
  attr(:errors, :list, default: [])
  attr(:class, :string, default: nil)
  attr(:wrapper_class, :string, default: nil)
  attr(:color, :string, default: nil)
  attr(:variant, :string, default: nil)
  attr(:rest, :global, include: ~w(min max step))

  def number_field(assigns) do
    ~H"""
    <div class={["mishka-numberfield-stub", @wrapper_class]}>
      <label :if={@label} for={@field.id} class="block text-sm font-medium mb-1">
        {@label}<span :if={@required} class="text-red-500"> *</span>
      </label>
      <input
        type="number"
        id={@field.id}
        name={@field.name}
        value={Phoenix.HTML.Form.normalize_value("number", @field.value)}
        placeholder={@placeholder}
        required={@required}
        class={["w-full border rounded px-3 py-2", @class]}
        {@rest}
      />
      <p :if={@hint} class="text-xs text-gray-500 mt-1">{@hint}</p>
      <p :for={{msg, _} <- @errors} class="text-xs text-red-600 mt-1">{msg}</p>
    </div>
    """
  end
end

defmodule MishkaChelekom.Components.EmailField do
  @moduledoc "Functional fallback for MishkaChelekom EmailField."

  use Phoenix.Component
  alias MishkaChelekom.Components.TextField

  attr(:field, Phoenix.HTML.FormField, required: true)
  attr(:rest, :global)
  attr(:label, :string, default: nil)
  attr(:placeholder, :string, default: nil)
  attr(:required, :boolean, default: false)
  attr(:hint, :string, default: nil)
  attr(:errors, :list, default: [])
  attr(:class, :string, default: nil)
  attr(:wrapper_class, :string, default: nil)
  attr(:color, :string, default: nil)
  attr(:variant, :string, default: nil)

  def email_field(assigns) do
    ~H"""
    <TextField.text_field
      type="email"
      field={@field}
      label={@label}
      placeholder={@placeholder}
      required={@required}
      hint={@hint}
      errors={@errors}
      class={@class}
      wrapper_class={@wrapper_class}
    />
    """
  end
end

defmodule MishkaChelekom.Components.PasswordField do
  @moduledoc "Functional fallback for MishkaChelekom PasswordField."

  use Phoenix.Component
  alias MishkaChelekom.Components.TextField

  attr(:field, Phoenix.HTML.FormField, required: true)
  attr(:label, :string, default: nil)
  attr(:placeholder, :string, default: nil)
  attr(:required, :boolean, default: false)
  attr(:hint, :string, default: nil)
  attr(:errors, :list, default: [])
  attr(:class, :string, default: nil)
  attr(:wrapper_class, :string, default: nil)
  attr(:color, :string, default: nil)
  attr(:variant, :string, default: nil)

  def password_field(assigns) do
    ~H"""
    <TextField.text_field
      type="password"
      field={@field}
      label={@label}
      placeholder={@placeholder}
      required={@required}
      hint={@hint}
      errors={@errors}
      class={@class}
      wrapper_class={@wrapper_class}
    />
    """
  end
end

defmodule MishkaChelekom.Components.DateTimeField do
  @moduledoc "Functional fallback for MishkaChelekom DateTimeField."

  use Phoenix.Component

  attr(:field, Phoenix.HTML.FormField, required: true)
  attr(:label, :string, default: nil)
  attr(:type, :string, default: "datetime-local")
  attr(:required, :boolean, default: false)
  attr(:hint, :string, default: nil)
  attr(:errors, :list, default: [])
  attr(:class, :string, default: nil)
  attr(:wrapper_class, :string, default: nil)
  attr(:color, :string, default: nil)
  attr(:variant, :string, default: nil)
  attr(:rest, :global)

  def date_time_field(assigns) do
    ~H"""
    <div class={["mishka-datetimefield-stub", @wrapper_class]}>
      <label :if={@label} for={@field.id} class="block text-sm font-medium mb-1">
        {@label}<span :if={@required} class="text-red-500"> *</span>
      </label>
      <input
        type={@type}
        id={@field.id}
        name={@field.name}
        value={Phoenix.HTML.Form.normalize_value(@type, @field.value)}
        required={@required}
        class={["w-full border rounded px-3 py-2", @class]}
        {@rest}
      />
      <p :if={@hint} class="text-xs text-gray-500 mt-1">{@hint}</p>
      <p :for={{msg, _} <- @errors} class="text-xs text-red-600 mt-1">{msg}</p>
    </div>
    """
  end
end

defmodule MishkaChelekom.Components.UrlField do
  @moduledoc "Functional fallback for MishkaChelekom UrlField."

  use Phoenix.Component
  alias MishkaChelekom.Components.TextField

  attr(:field, Phoenix.HTML.FormField, required: true)
  attr(:label, :string, default: nil)
  attr(:placeholder, :string, default: nil)
  attr(:required, :boolean, default: false)
  attr(:hint, :string, default: nil)
  attr(:errors, :list, default: [])
  attr(:class, :string, default: nil)
  attr(:wrapper_class, :string, default: nil)
  attr(:color, :string, default: nil)
  attr(:variant, :string, default: nil)

  def url_field(assigns) do
    ~H"""
    <TextField.text_field
      type="url"
      field={@field}
      label={@label}
      placeholder={@placeholder}
      required={@required}
      hint={@hint}
      errors={@errors}
      class={@class}
      wrapper_class={@wrapper_class}
    />
    """
  end
end
