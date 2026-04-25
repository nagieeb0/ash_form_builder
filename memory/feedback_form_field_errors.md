---
name: Phoenix.HTML.FormField error extraction
description: form[field_name].errors is [{String.t(), keyword()}] tuples, not a keyword list
type: feedback
---

`Phoenix.HTML.FormField.errors` (accessed via `form[field_name]`) is a list of `{message, opts}` tuples.
`Keyword.get_values/2` does NOT work on it.

**Wrong:**
```elixir
field = form[field_name]
Keyword.get_values(field.errors, :message)  # returns [] always
```

**Right:**
```elixir
case form[field_name] do
  nil -> []
  form_field when is_struct(form_field) -> Enum.map(form_field.errors, &elem(&1, 0))
  _ -> []
end
```

Also: `Map.has_key?(form, field_name)` on a `Phoenix.HTML.Form` struct checks the struct's own
fields (`:id`, `:name`, `:data`, etc.), NOT form field names. It will always return false for
field names like `:email`. Use `form[field_name]` via the Access protocol instead.

**Why:** Discovered when debugging nil error message extraction in themes.

**How to apply:** Any time error messages are extracted from a Phoenix.HTML.Form in theme code.
