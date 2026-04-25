---
name: Theme architecture patterns
description: Key decisions in Glassmorphism/Shadcn theme structure and feature expansion
type: project
---

Glassmorphism and Shadcn themes (in `lib/ash_form_builder/themes/`) share the same architecture:

**Field type dispatch in `render_field/2`:**
- `:boolean` and `:checkbox` → `render_toggle/1` (CSS-only toggle using Tailwind `peer` utilities)
- `:array` → `render_array_field/1` (multi-select with options, or comma-textarea without)
- `:text_input` with `opts[:max_length] > 255` → auto-promoted to `:textarea` before dispatch
- `:date` / `:datetime` → fall through to `field_input/1` which uses native HTML5 `type="date"` / `type="datetime-local"`
- All other types go through `render_standard_field/1` → `field_input/1` pattern clauses

**render_nested/1 is now IMPLEMENTED** (not returning nil) in both themes.
Both themes produce fully themed nested form blocks with styled add/remove buttons.
CSS classes `btn-add-nested` and `btn-remove-nested` are preserved for test compatibility.

**Mix generator:** `lib/mix/tasks/ash_form_builder.gen.form.ex`
Usage: `mix ash_form_builder.gen.form MyApp.Accounts.User [--action create] [--out dir] [--component]`

**dialyzer:** NOT configured (mix task not available)
**credo:** NOT configured (no .credo.exs)
