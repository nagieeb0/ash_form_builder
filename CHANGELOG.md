# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned
- Better creatable value extraction (pass raw input from JS)
- Loading states for create operations
- Inline error display for failed creations
- Confirmation dialogs before creating
- Bulk create support
- i18n support via GetText
- Field-level permissions
- Conditional field rendering
- Multi-step form wizards
- Form draft auto-save

## [0.1.1] - 2024-12-19

### Added
- Enhanced documentation configuration for hexdocs.pm
- Comprehensive guides in `guides/` directory
- Todo App integration tutorial
- Relationships guide (has_many vs many_to_many)
- Documentation structure guide

### Changed
- Version bumped to 0.1.1 for documentation improvements
- Simplified ExDoc configuration for better compatibility

### Fixed
- Documentation main page now correctly shows AshFormBuilder module

## [0.1.0] - 2024-12-19

### Added
- **Initial release** - EXPERIMENTAL
- Auto-inference engine for form fields from Ash actions
- Spark DSL extension for form configuration
- Many-to-many relationship support with searchable combobox
- **Creatable combobox** - create related records on-the-fly
- has_many nested forms with dynamic add/remove
- Theme system with Default and MishkaChelekom adapters
- Domain Code Interface integration
- FormComponent LiveComponent with event handling
- FormRenderer with theme delegation
- Comprehensive test suite
- Integration guides (Todo App, Relationships)

### Known Issues
- Creatable value extraction uses regex (should pass raw input)
- No loading states for async operations
- Limited i18n support
- No field-level permission system

### Dependencies
- Elixir ~> 1.17
- Spark ~> 2.0
- Ash ~> 3.0
- AshPhoenix ~> 2.0
- Phoenix LiveView ~> 1.0
- Phoenix ~> 1.7
- PhoenixHTML ~> 4.0

---

## Experimental Status Notice

**This package is EXPERIMENTAL and under active development.**

- API may change without notice
- Breaking changes likely in minor versions
- Use in production at your own risk
- Not all edge cases are handled
- Documentation may be incomplete

For production use, consider:
1. Pinning to exact version: `{:ash_form_builder, "== 0.1.1"}`
2. Monitoring the repository for updates
3. Testing thoroughly before deployment
4. Being prepared to handle breaking changes on upgrade
