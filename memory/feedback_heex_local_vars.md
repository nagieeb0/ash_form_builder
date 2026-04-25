---
name: HEEx local variable rules
description: Never use local variables or @module_attrs inside ~H; always assign them to assigns first
type: feedback
---

Never compute a value as a local variable and then reference it inside a `~H` sigil. This produces
a "accessing variable X inside a LiveView template" warning that becomes a compile error with
`--warnings-as-errors`.

**Wrong:**
```elixir
defp field_input(assigns) do
  input_type = html_input_type(@field.type)  # @field is also wrong outside ~H
  ~H"""
  <input type={input_type} />  # local var = warning
  """
end
```

**Right:**
```elixir
defp field_input(assigns) do
  assigns = assign(assigns, :input_type, html_input_type(assigns.field.type))
  ~H"""
  <input type={@input_type} />
  """
end
```

**Why:** `@field` outside `~H` refers to an Elixir module attribute, not the assigns map. Inside `~H`,
only `@assign_key` syntax and already-bound function args are safe.

**How to apply:** Whenever a private component function needs to compute a derived value before rendering,
pipe through `assign(assigns, :key, value)` then use `@key` inside the template.
