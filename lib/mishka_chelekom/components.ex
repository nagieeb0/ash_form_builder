defmodule MishkaChelekom.Components.Combobox do
  @moduledoc """
  Stub module for MishkaChelekom Combobox component.

  This module is a placeholder. The actual component must be generated
  in your host application using:

      mix mishka.ui.gen.component combobox

  The generated component will override this stub at runtime.
  """

  use Phoenix.Component

  def combobox(assigns) do
    ~H"""
    <div class="mishka-combobox-stub">
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  def combobox_input(assigns) do
    rest =
      assigns
      |> Map.drop([:__changed__, :inner_block])
      |> Phoenix.Component.assigns_to_attributes([:field, :placeholder])

    assigns = assign(assigns, :rest, rest)

    ~H"""
    <input type="text" class="mishka-combobox-input-stub" {@rest} />
    """
  end

  def combobox_options(assigns) do
    ~H"""
    <div class="mishka-combobox-options-stub">
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  def combobox_option(assigns) do
    ~H"""
    <div class="mishka-combobox-option-stub">
      <%= render_slot(@inner_block) %>
    </div>
    """
  end
end

defmodule MishkaChelekom.Components.TextField do
  @moduledoc """
  Stub module for MishkaChelekom TextField component.
  Generate with: mix mishka.ui.gen.component text_field
  """

  use Phoenix.Component

  def text_field(assigns) do
    errors =
      case assigns[:field] do
        %{errors: errs} when is_list(errs) -> errs
        _ -> []
      end

    assigns = assign(assigns, :errors, errors)

    ~H"""
    <input type="text" class="mishka-textfield-stub" />
    <div :if={@errors != []} class="mishka-textfield-errors-stub">
      <span :for={{msg, _} <- @errors}>{msg}</span>
    </div>
    """
  end
end

defmodule MishkaChelekom.Components.TextareaField do
  @moduledoc """
  Stub module for MishkaChelekom TextareaField component.
  Generate with: mix mishka.ui.gen.component textarea_field
  """

  use Phoenix.Component

  def textarea_field(assigns) do
    ~H"""
    <textarea class="mishka-textareafield-stub"></textarea>
    """
  end
end

defmodule MishkaChelekom.Components.NativeSelect do
  @moduledoc """
  Stub module for MishkaChelekom NativeSelect component.
  Generate with: mix mishka.ui.gen.component native_select
  """

  use Phoenix.Component

  def native_select(assigns) do
    ~H"""
    <select class="mishka-nativeselect-stub">
      <option>Stub Option</option>
    </select>
    """
  end
end

defmodule MishkaChelekom.Components.CheckboxField do
  @moduledoc """
  Stub module for MishkaChelekom CheckboxField component.
  Generate with: mix mishka.ui.gen.component checkbox_field
  """

  use Phoenix.Component

  def checkbox_field(assigns) do
    ~H"""
    <input type="checkbox" class="mishka-checkboxfield-stub" />
    """
  end
end

defmodule MishkaChelekom.Components.NumberField do
  @moduledoc """
  Stub module for MishkaChelekom NumberField component.
  Generate with: mix mishka.ui.gen.component number_field
  """

  use Phoenix.Component

  def number_field(assigns) do
    ~H"""
    <input type="number" class="mishka-numberfield-stub" />
    """
  end
end

defmodule MishkaChelekom.Components.EmailField do
  @moduledoc """
  Stub module for MishkaChelekom EmailField component.
  Generate with: mix mishka.ui.gen.component email_field
  """

  use Phoenix.Component

  def email_field(assigns) do
    ~H"""
    <input type="email" class="mishka-emailfield-stub" />
    """
  end
end

defmodule MishkaChelekom.Components.PasswordField do
  @moduledoc """
  Stub module for MishkaChelekom PasswordField component.
  Generate with: mix mishka.ui.gen.component password_field
  """

  use Phoenix.Component

  def password_field(assigns) do
    ~H"""
    <input type="password" class="mishka-passwordfield-stub" />
    """
  end
end

defmodule MishkaChelekom.Components.DateTimeField do
  @moduledoc """
  Stub module for MishkaChelekom DateTimeField component.
  Generate with: mix mishka.ui.gen.component date_time_field
  """

  use Phoenix.Component

  def date_time_field(assigns) do
    ~H"""
    <input type="datetime-local" class="mishka-datetimefield-stub" />
    """
  end
end

defmodule MishkaChelekom.Components.UrlField do
  @moduledoc """
  Stub module for MishkaChelekom UrlField component.
  Generate with: mix mishka.ui.gen.component url_field
  """

  use Phoenix.Component

  def url_field(assigns) do
    ~H"""
    <input type="url" class="mishka-urlfield-stub" />
    """
  end
end
