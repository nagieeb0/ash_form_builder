# AshFormBuilder Memory Index

- [HEEx local variable rules](feedback_heex_local_vars.md) — Never use local vars inside ~H; always assign to socket/assigns first
- [Phoenix.HTML.FormField error extraction](feedback_form_field_errors.md) — Use Enum.map(form_field.errors, &elem(&1, 0)), not Keyword.get_values
- [Nested form double-render bug](project_nested_form_bug.md) — FormRenderer had duplicate inputs_for for :one cardinality; fixed
- [Theme architecture patterns](project_theme_architecture.md) — Field type dispatch, new :boolean/:array types, mix generator location
