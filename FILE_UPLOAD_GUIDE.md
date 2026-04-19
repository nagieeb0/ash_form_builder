# File Uploads - Complete Guide

## Overview

AshFormBuilder provides **declarative file uploads** with automatic:
- ✅ File path storage (no helper functions needed)
- ✅ Existing file preview in update forms
- ✅ Image thumbnails for visual files
- ✅ File deletion with restore capability
- ✅ Multiple file support
- ✅ Upload progress tracking
- ✅ Validation error display

## Quick Start

### 1. Basic File Upload

```elixir
defmodule MyApp.Users.User do
  use Ash.Resource,
    domain: MyApp.Users,
    extensions: [AshFormBuilder]

  attributes do
    uuid_primary_key :id
    attribute :name, :string, allow_nil?: false
    attribute :avatar_path, :string  # ← Auto-detected target
  end

  actions do
    create :create do
      accept [:name]
      argument :avatar, :string, allow_nil?: true
      # No manual change function needed!
    end
  end

  form do
    action :create
    
    field :avatar do
      type :file_upload
      label "Profile Photo"
      
      opts upload: [
        cloud: MyApp.Buckets.Cloud,
        max_entries: 1,
        max_file_size: 5_000_000,
        accept: ~w(.jpg .jpeg .png)
      ]
    end
  end
end
```

**What happens automatically:**
1. Field `:avatar` → stores to attribute `:avatar_path` (auto-detected)
2. File uploaded via Phoenix LiveView
3. Path stored via `Buckets.Cloud`
4. No helper function required!

### 2. Update Form with Existing File Preview

```elixir
defmodule MyAppWeb.UserLive.Edit do
  use MyAppWeb, :live_view

  def mount(%{"id" => id}, _session, socket) do
    user = MyApp.Users.get_user!(id, load: [])
    
    # for_update auto-loads existing avatar_path
    form = MyApp.Users.User.Form.for_update(user,
      actor: socket.assigns.current_user
    )
    
    {:ok, assign(socket, form: form, user: user)}
  end

  def render(assigns) do
    ~H"""
    <.live_component
      module={AshFormBuilder.FormComponent}
      id="user-form"
      resource={MyApp.Users.User}
      form={@form}
    />
    """
  end
end
```

**Features in update forms:**
- ✅ Shows existing file with icon/thumbnail
- ✅ Image files show preview thumbnail
- ✅ Non-image files show document icon
- ✅ Click delete button to mark for removal
- ✅ Click restore to undo deletion
- ✅ Upload new file to replace existing

## Configuration Options

### Upload Configuration

```elixir
field :avatar do
  type :file_upload
  label "Profile Photo"
  
  opts upload: [
    # Required: Cloud module for storage
    cloud: MyApp.Buckets.Cloud,
    
    # Optional: Max files (default: 1)
    max_entries: 1,
    
    # Optional: Max size in bytes (default: 8_000_000)
    max_file_size: 5_000_000,
    
    # Optional: Accepted file types (default: :any)
    accept: ~w(.jpg .jpeg .png),
    
    # Optional: Bucket name for storage
    bucket_name: :user_avatars,
    
    # Optional: Explicit target attribute (auto-detected by default)
    target_attribute: :avatar_path
  ]
end
```

### Auto-Detection Rules

**Field Name → Target Attribute:**
- `:avatar` → `:avatar_path`
- `:proposal` → `:proposal_path`
- `:document` → `:document_path`
- `:attachment` → `:attachment_path`

**Override with `target_attribute`:**
```elixir
field :resume do
  type :file_upload
  
  opts upload: [
    cloud: MyApp.Cloud,
    target_attribute: :cv_path  # Custom attribute name
  ]
end
```

## Multiple File Uploads

```elixir
field :attachments do
  type :file_upload
  label "Attachments"
  hint "Upload multiple documents (max 5)"
  
  opts upload: [
    cloud: MyApp.Cloud,
    max_entries: 5,
    max_file_size: 10_000_000,
    accept: ~w(.pdf .doc .docx)
  ]
end
```

**Features:**
- Shows all existing files in grid layout
- Delete individual files
- Upload multiple new files at once
- Stores as array: `[:path1, :path2, :path3]`

## File Deletion

### How It Works

1. **Click delete button** on existing file preview
2. File preview gets strikethrough + opacity reduced
3. Hidden input `#{field}_delete` set to `"true"`
4. On form submit, attribute set to `nil`
5. Click restore button to undo before submit

### Visual States

**Normal State:**
```
┌─────────────────────┐
│ [📄] resume.pdf     │  ← Delete button (hover)
│ Click delete to remove│
└─────────────────────┘
```

**Deleted State:**
```
┌─────────────────────┐
│ [📄] resume.pdf     │  ← Restore button (green)
│ ✓ Marked for deletion│
└─────────────────────┘
```

## Image Preview

**Supported image formats:**
- `.jpg`, `.jpeg`
- `.png`
- `.gif`
- `.webp`
- `.svg`
- `.bmp`

**Fallback:**
- If image fails to load (broken URL), shows document icon
- Non-image files always show document icon

## Cloud Storage Configuration

### Volume Adapter (Local Storage)

```elixir
# config/config.exs
config :my_app, MyApp.Buckets.Cloud,
  adapter: Buckets.Adapters.Volume,
  bucket: "priv/uploads",
  base_url: "http://localhost:4000/uploads"
```

### S3 Adapter

```elixir
config :my_app, MyApp.Buckets.Cloud,
  adapter: Buckets.Adapters.S3,
  bucket: "my-app-bucket",
  access_key_id: System.get_env("AWS_ACCESS_KEY_ID"),
  secret_access_key: System.get_env("AWS_SECRET_ACCESS_KEY"),
  region: "us-east-1"
```

### Multiple Buckets

```elixir
# Different buckets for different file types
field :avatar do
  type :file_upload
  opts upload: [
    cloud: MyApp.AvatarCloud,  # Dedicated avatar bucket
    bucket_name: :user_avatars
  ]
end

field :document do
  type :file_upload
  opts upload: [
    cloud: MyApp.DocumentCloud,  # Dedicated document bucket
    bucket_name: :user_documents
  ]
end
```

## Complete Example

```elixir
defmodule MyApp.Projects.Project do
  use Ash.Resource,
    domain: MyApp.Projects,
    extensions: [AshFormBuilder]

  attributes do
    uuid_primary_key :id
    attribute :name, :string, allow_nil?: false
    attribute :proposal_path, :string
    attribute :contract_path, :string
    attribute :attachments, {:array, :string}, default: []
  end

  actions do
    create :create do
      accept [:name]
      argument :proposal, :string, allow_nil?: true
      argument :contract, :string, allow_nil?: true
      argument :attachments, {:array, :string}, allow_nil?: true
    end

    update :update do
      accept [:name]
      argument :proposal, :string, allow_nil?: true
      argument :contract, :string, allow_nil?: true
      argument :attachments, {:array, :string}, allow_nil?: true
    end
  end

  form do
    action :create
    submit_label "Create Project"

    # Single file with image preview
    field :proposal do
      type :file_upload
      label "Project Proposal"
      hint "PDF or Word document (max 10 MB)"
      
      opts upload: [
        cloud: MyApp.Projects.Cloud,
        max_entries: 1,
        max_file_size: 10_000_000,
        accept: ~w(.pdf .doc .docx)
      ]
    end

    # Single file with custom target
    field :contract do
      type :file_upload
      label "Signed Contract"
      hint "Upload signed contract"
      
      opts upload: [
        cloud: MyApp.Projects.Cloud,
        max_entries: 1,
        max_file_size: 10_000_000,
        accept: ~w(.pdf .jpg .jpeg .png),
        target_attribute: :contract_path  # Explicit mapping
      ]
    end

    # Multiple files
    field :attachments do
      type :file_upload
      label "Additional Attachments"
      hint "Upload up to 5 files"
      
      opts upload: [
        cloud: MyApp.Projects.Cloud,
        max_entries: 5,
        max_file_size: 10_000_000,
        accept: ~w(.pdf .doc .docx .xls .xlsx)
      ]
    end
  end
end
```

## Testing

```elixir
defmodule MyAppWeb.ProjectLive.FormTest do
  use MyAppWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  test "upload and delete file", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, MyAppWeb.ProjectLive.Form)

    # Upload file
    upload =
      file_input(view, "#project-form", :proposal, [
        %{
          name: "proposal.pdf",
          content: :binary.copy(<<0x25, 0x50, 0x44, 0x46>>, 100),
          type: "application/pdf"
        }
      ])

    render_upload(upload, 100)

    # Submit form
    view
    |> form("#project-form", %{"name" => "Test Project"})
    |> render_submit()

    assert render(view) =~ "Project created successfully!"
  end

  test "delete existing file in update form", %{conn: conn} do
    project = create_project_with_proposal()
    
    {:ok, view, _html} = live_isolated(conn, MyAppWeb.ProjectLive.Form, 
      params: %{"id" => project.id}
    )

    # Verify existing file shown
    html = render(view)
    assert html =~ "proposal.pdf"

    # Click delete
    view |> element("[phx-value-field=\"proposal\"]") |> render_click()

    # Verify delete state
    html = render(view)
    assert html =~ "Marked for deletion"

    # Submit to confirm deletion
    view
    |> form("#project-form", %{"name" => "Updated Project"})
    |> render_submit()

    # Verify file was deleted
    project = MyApp.Projects.get_project!(project.id)
    assert is_nil(project.proposal_path)
  end
end
```

## Migration from Helper Functions

### Before (Manual)

```elixir
actions do
  create :create do
    accept [:name]
    argument :avatar, :string, allow_nil?: true
    
    change fn changeset, _ ->
      case Ash.Changeset.get_argument(changeset, :avatar) do
        nil -> changeset
        path -> Ash.Changeset.change_attribute(changeset, :avatar_path, path)
      end
    end
  end
end
```

### After (Automatic)

```elixir
actions do
  create :create do
    accept [:name]
    argument :avatar, :string, allow_nil?: true
    # That's it! No helper function needed.
  end
end
```

## Troubleshooting

### File not saving

**Problem:** File uploads but path not saved to database.

**Solution:** Ensure attribute name matches field name + `_path`:
```elixir
field :avatar  # → looks for :avatar_path attribute
```

Or use explicit `target_attribute`:
```elixir
opts upload: [target_attribute: :custom_path]
```

### Existing file not showing

**Problem:** Update form doesn't show existing file.

**Solution:** Ensure form loads existing value:
```elixir
form = Resource.Form.for_update(record, ...)
```

The form automatically picks up `record.avatar_path` value.

### Delete not working

**Problem:** File marked for deletion but not removed on submit.

**Solution:** Check that:
1. Hidden input `#{field}_delete` is present in form
2. `toggle_file_delete` event handled by FormComponent
3. On submit, `consume_file_uploads` checks delete flag

## Areas of Enhancement

### Implemented ✅
- [x] Automatic file path storage (no helper function)
- [x] Existing file preview in update forms
- [x] Image thumbnail preview
- [x] File deletion with restore
- [x] Multiple file support
- [x] Bucket name configuration
- [x] Custom target attribute

### Future Enhancements
- [ ] Drag-and-drop upload zone
- [ ] Client-side image compression
- [ ] Progress bar for batch uploads
- [ ] File type icons (PDF, Word, Excel, etc.)
- [ ] Direct-to-S3 uploads (presigned URLs)
- [ ] Automatic file cleanup from storage on delete
- [ ] File metadata storage (size, type, dimensions)
- [ ] Cropping/resizing for images
