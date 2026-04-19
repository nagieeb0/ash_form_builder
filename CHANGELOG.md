# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned for 0.3.0
- i18n support via GetText
- Field-level permissions
- Conditional field rendering
- Multi-step form wizards
- Form draft auto-save

## [0.2.0] - 2024-12-19

### ✨ Added - Production-Ready Features

#### Zero-Config Field Inference
- Enhanced `AshFormBuilder.Infer` engine with complete type mapping
- Auto-detection of all Ash types: string, text, boolean, integer, float, decimal, date, datetime, atom, enum
- Smart defaults for all field types (labels, required status, placeholders)
- Automatic relationship detection (many_to_many → combobox, has_many → nested forms)

#### Advanced Relationship Handling
- Robust `manage_relationship` support for create, update, and destroy operations
- Automatic UI inference based on relationship type and manage_relationship configuration
- Support for deeply nested structures (3+ levels) with correct path mapping
- Performance optimization using Phoenix.LiveComponent boundaries

#### Pluggable Theme System
- Refactored `AshFormBuilder.Theme` behaviour for comprehensive UI kit support
- Support for Tailwind CSS, DaisyUI, and custom component libraries
- MishkaTheme as primary example with full component integration
- Custom theme injection for specific field types

#### Searchable/Creatable Combobox
- Server-side search integration via Ash.Query
- Real-time combobox option updates via LiveView push_event
- Creatable functionality with immediate record creation and selection
- Automatic destination_resource interaction respecting Ash policies

#### Comprehensive Testing
- AshFormBuilder.Test helpers using Ash.Test and Phoenix.LiveViewTest
- Integration tests for auto-inference correctness
- Nested form validation rendering tests
- Many-to-many selection state tests

### 🔧 Changed - Architecture Improvements

#### Infer Engine Refactoring
- Complete rewrite of `AshFormBuilder.Infer.infer_fields/3` for zero-config operation
- Added `:ignore_fields` option to exclude specific fields (default: [:id, :inserted_at, :updated_at])
- Added `:include_timestamps` option to include timestamp fields
- Added `:many_to_many_as` option to customize relationship UI type
- Smart constraint detection (one_of → select, enum modules → select)

#### DSL Enhancements
- Added `:ignore` option to field DSL for excluding fields without full block
- Added `:order` option to customize field rendering order
- Added `:override` option to replace inferred field completely
- Form-level `:ignore_fields` and `:field_order` options

#### Theme System Upgrade
- Theme behaviour now supports comprehensive component injection
- Added `render_nested/1` callback for custom nested form rendering
- Theme opts passed through entire rendering pipeline
- Support for custom field types via theme extension

### 📦 Metadata & Documentation

#### Hex.pm Presence
- Complete package metadata with all links and requirements
- Professional README with badges, pitch, and 3-line quick start
- Comprehensive guides (Todo App Integration, Relationships Guide)
- Module documentation with examples for all public APIs

#### Documentation Structure
- Core API modules grouped separately from data structures
- Themes documented with usage examples
- Internal transformers marked as internal
- Skip undefined reference warnings for CHANGELOG

### 🐛 Fixed

- Combobox creatable value extraction (now uses proper parameter passing)
- Nested form path mapping for deeply nested structures
- Theme assign tracking for LiveView re-rendering
- Documentation main page redirect to AshFormBuilder module

### ⚠️ Breaking Changes from 0.1.x

#### Theme Behaviour
- `render_field/2` now requires opts parameter (previously optional)
- Themes must use `Map.put/3` instead of `assign/3` for assign maps

#### Infer Engine
- Default ignore fields now includes [:id, :inserted_at, :updated_at]
- Timestamps not included by default (use `:include_timestamps` option)

#### Migration Guide

```elixir
# 0.1.x theme
def render_field(assigns), do: ...

# 0.2.0 theme
def render_field(assigns, opts), do: ...
```

```elixir
# 0.1.x - timestamps included by default
form do
  action :create
end

# 0.2.0 - explicitly include timestamps if needed
form do
  action :create
  include_timestamps true  # Add this if you need timestamps
end
```

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

## Experimental Status Notice (v0.1.x)

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
