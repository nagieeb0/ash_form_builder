defmodule AshFormBuilder.Themes do
  @moduledoc """
  Pluggable theme registry.

  Themes can be referenced anywhere in the library by either:

  * **A theme module** — `AshFormBuilder.Themes.Default`
  * **A short atom** — `:default`, `:shadcn`, `:glassmorphism`, `:mishka`,
    or any user-registered name.

  ## Built-in shortnames

  | atom              | module                                  |
  |-------------------|------------------------------------------|
  | `:default`        | `AshFormBuilder.Themes.Default`          |
  | `:shadcn`         | `AshFormBuilder.Themes.Shadcn`           |
  | `:glassmorphism`  | `AshFormBuilder.Themes.Glassmorphism`    |
  | `:mishka`         | `AshFormBuilder.Theme.MishkaTheme`       |

  ## Registering your own theme

      # config/config.exs
      config :ash_form_builder, :themes,
        my_brand: MyAppWeb.Themes.MyBrand,
        retro: MyAppWeb.Themes.Retro

  Then reference by short name from the DSL:

      forms do
        form :create do
          theme :my_brand
        end
      end

  Implement the `AshFormBuilder.Theme` behaviour and you're done — no
  module-name conventions or path tricks required.
  """

  @builtin %{
    default: AshFormBuilder.Themes.Default,
    shadcn: AshFormBuilder.Themes.Shadcn,
    glassmorphism: AshFormBuilder.Themes.Glassmorphism,
    mishka: AshFormBuilder.Theme.MishkaTheme
  }

  @doc """
  Resolve a theme reference to a module.

  Accepts a module (returned as-is), a known short atom, or a
  user-registered atom. Raises `KeyError` if the atom is unknown so
  typos surface immediately at compile time when used from a DSL.

  ## Examples

      iex> AshFormBuilder.Themes.resolve(:default)
      AshFormBuilder.Themes.Default

      iex> AshFormBuilder.Themes.resolve(AshFormBuilder.Themes.Shadcn)
      AshFormBuilder.Themes.Shadcn
  """
  @spec resolve(atom() | module()) :: module()
  def resolve(name) when is_atom(name) do
    cond do
      Map.has_key?(@builtin, name) ->
        Map.fetch!(@builtin, name)

      Map.has_key?(user_registry(), name) ->
        Map.fetch!(user_registry(), name)

      module?(name) ->
        name

      true ->
        raise KeyError,
          message:
            "Unknown theme #{inspect(name)}. Built-in themes: " <>
              "#{inspect(Map.keys(@builtin))}. Register your own under " <>
              "`config :ash_form_builder, :themes, name: MyTheme`."
    end
  end

  @doc "All registered theme names (built-in + user)."
  @spec list() :: [atom()]
  def list do
    Map.keys(@builtin) ++ Map.keys(user_registry())
  end

  @doc "Returns true if the given atom is a registered theme name."
  @spec registered?(atom()) :: boolean()
  def registered?(name) when is_atom(name) do
    Map.has_key?(@builtin, name) or Map.has_key?(user_registry(), name)
  end

  defp user_registry do
    case Application.get_env(:ash_form_builder, :themes, []) do
      list when is_list(list) -> Enum.into(list, %{})
      map when is_map(map) -> map
      _ -> %{}
    end
  end

  # Heuristic — atoms whose printable form starts with `Elixir.` are
  # module names. Avoids `Code.ensure_loaded?/1` so this works during
  # compile-time DSL validation before all modules are linked.
  defp module?(name) do
    name |> Atom.to_string() |> String.starts_with?("Elixir.")
  end
end
