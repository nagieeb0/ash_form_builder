---
name: Nested form double-render bug (fixed)
description: FormRenderer had a duplicate inputs_for block for :one cardinality nested forms
type: project
---

`FormRenderer.render_default_nested_form/1` had a bug: it contained one shared `<.inputs_for>`
block (which renders for ALL cardinalities) and a second `<div :if={cardinality == :one}>` block
that called `inputs_for` again. For `:one` cardinality, fields were rendered twice.

**Fix:** Removed the redundant `:one` block entirely. The single `inputs_for` loop handles both
cardinalities correctly; the remove button inside uses `:if={@nested.cardinality == :many}` so
it only appears when appropriate.

**Why:** The `:one` block was likely added as a special case but the author forgot the shared
`inputs_for` at the top already covered it.

**How to apply:** When auditing nested form rendering, verify `inputs_for` is called exactly once
per nested form block.
