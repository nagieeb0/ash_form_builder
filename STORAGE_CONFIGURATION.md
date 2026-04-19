# Storage Configuration Guide

## Choosing Where to Store Files

AshFormBuilder uses the `buckets` library for file storage. Here's how to configure storage locations properly.

## Storage Adapters

### 1. Volume Adapter (Local File System)

**Best for:** Development, small apps, single-server deployments

```elixir
# config/config.exs
config :my_app, MyApp.Buckets.Cloud,
  adapter: Buckets.Adapters.Volume,
  bucket: "priv/uploads",  # Relative to your app root
  base_url: "http://localhost:4000/uploads"
```

**Directory Structure:**
```
priv/
  uploads/
    avatars/
      abc123-profile.jpg
    documents/
      xyz789-report.pdf
```

**Pros:**
- ✅ Simple setup
- ✅ No external dependencies
- ✅ Fast local access
- ✅ No API costs

**Cons:**
- ❌ Doesn't scale across multiple servers
- ❌ No CDN integration
- ❌ Manual backup required
- ❌ Limited bandwidth

### 2. S3 Adapter (Amazon S3 / Compatible)

**Best for:** Production, scalable apps, multi-server deployments

```elixir
# config/config.exs
config :my_app, MyApp.Buckets.Cloud,
  adapter: Buckets.Adapters.S3,
  bucket: "my-app-bucket",
  access_key_id: System.get_env("AWS_ACCESS_KEY_ID"),
  secret_access_key: System.get_env("AWS_SECRET_ACCESS_KEY"),
  region: "us-east-1",
  # Optional: Custom endpoint for S3-compatible services
  # endpoint: "https://nyc3.digitaloceanspaces.com",
  # Optional: Force path-style URLs (for MinIO, etc.)
  # force_path_style: true
```

**S3-Compatible Services:**
- Amazon S3
- DigitalOcean Spaces
- MinIO (self-hosted)
- Wasabi
- Cloudflare R2

**Pros:**
- ✅ Infinite scalability
- ✅ Built-in redundancy
- ✅ CDN integration
- ✅ Automatic backups
- ✅ Access controls

**Cons:**
- ❌ API costs (can add up)
- ❌ Latency for large files
- ❌ Vendor lock-in concerns

### 3. GCS Adapter (Google Cloud Storage)

**Best for:** Apps already on GCP, ML/AI workloads

```elixir
config :my_app, MyApp.Buckets.Cloud,
  adapter: Buckets.Adapters.GCS,
  bucket: "my-app-bucket",
  service_account_credentials: System.get_env("GCP_SERVICE_ACCOUNT_JSON"),
  project_id: "my-gcp-project"
```

## Recommended Bucket Structure

### Option 1: Single Bucket with Prefixes (Recommended)

```
my-app-bucket/
├── dev/
│   ├── avatars/
│   ├── documents/
│   └── attachments/
├── prod/
│   ├── avatars/
│   ├── documents/
│   └── attachments/
```

**Configuration:**
```elixir
# Use bucket_name in upload opts to specify subdirectory
field :avatar do
  type :file_upload
  opts upload: [
    cloud: MyApp.Buckets.Cloud,
    bucket_name: "prod/avatars"  # ← Organize by type
  ]
end

field :document do
  type :file_upload
  opts upload: [
    cloud: MyApp.Buckets.Cloud,
    bucket_name: "prod/documents"
  ]
end
```

### Option 2: Separate Buckets per Type

```
my-app-avatars/
my-app-documents/
my-app-attachments/
```

**Configuration:**
```elixir
# Define separate cloud modules
defmodule MyApp.AvatarCloud do
  use Buckets.Cloud, otp_app: :my_app
end

defmodule MyApp.DocumentCloud do
  use Buckets.Cloud, otp_app: :my_app
end

# Config
config :my_app, MyApp.AvatarCloud,
  adapter: Buckets.Adapters.S3,
  bucket: "my-app-avatars"

config :my_app, MyApp.DocumentCloud,
  adapter: Buckets.Adapters.S3,
  bucket: "my-app-documents"

# Usage
field :avatar do
  type :file_upload
  opts upload: [
    cloud: MyApp.AvatarCloud  # ← Different cloud module
  ]
end
```

## Environment-Specific Configuration

### Development

```elixir
# config/dev.exs
config :my_app, MyApp.Buckets.Cloud,
  adapter: Buckets.Adapters.Volume,
  bucket: "priv/uploads/dev",
  base_url: "http://localhost:4000/uploads"
```

### Test

```elixir
# config/test.exs
config :my_app, MyApp.Buckets.Cloud,
  adapter: Buckets.Adapters.Volume,
  bucket: "tmp/test_uploads",  # Auto-cleaned
  base_url: "http://localhost:4000/uploads"
```

### Production

```elixir
# config/prod.exs
config :my_app, MyApp.Buckets.Cloud,
  adapter: Buckets.Adapters.S3,
  bucket: System.get_env("S3_BUCKET"),
  access_key_id: System.get_env("AWS_ACCESS_KEY_ID"),
  secret_access_key: System.get_env("AWS_SECRET_ACCESS_KEY"),
  region: System.get_env("AWS_REGION", "us-east-1")
```

## Multi-Tenant Storage

For SaaS applications with tenant isolation:

### Option 1: Path-Based Isolation

```elixir
field :document do
  type :file_upload
  opts upload: [
    cloud: MyApp.Buckets.Cloud,
    bucket_name: "tenants/#{tenant_id}/documents"
  ]
end
```

**Structure:**
```
bucket/
├── tenants/
│   ├── tenant-1/
│   │   ├── documents/
│   │   └── avatars/
│   └── tenant-2/
│       ├── documents/
│       └── avatars/
```

### Option 2: Dynamic Configuration

```elixir
# In your LiveView or controller
tenant_config = [
  adapter: Buckets.Adapters.S3,
  bucket: "tenant-#{tenant.id}-bucket",
  access_key_id: tenant.s3_key,
  secret_access_key: tenant.s3_secret
]

MyApp.Buckets.Cloud.put_dynamic_config(tenant_config)
```

## File Organization Best Practices

### 1. Use UUIDs for Filenames

```elixir
# AshFormBuilder does this automatically
# Stored as: uploads/abc123def456-original_filename.pdf
```

**Why:**
- Avoids filename collisions
- Prevents directory traversal attacks
- Hides original filenames (privacy)

### 2. Organize by Date

```elixir
opts upload: [
  cloud: MyApp.Cloud,
  bucket_name: "documents/#{Date.to_iso8601(:calendar.date())}"
]
```

**Structure:**
```
documents/
├── 2024-01-15/
├── 2024-01-16/
└── 2024-01-17/
```

### 3. Organize by Resource Type

```elixir
# For User avatars
opts upload: [
  cloud: MyApp.Cloud,
  bucket_name: "users/avatars"
]

# For Project documents
opts upload: [
  cloud: MyApp.Cloud,
  bucket_name: "projects/documents"
]
```

## Complete Configuration Example

```elixir
# config/config.exs
import Config

# Base cloud configuration
config :my_app, MyApp.Buckets.Cloud,
  adapter: Buckets.Adapters.S3,
  access_key_id: System.get_env("AWS_ACCESS_KEY_ID"),
  secret_access_key: System.get_env("AWS_SECRET_ACCESS_KEY"),
  region: System.get_env("AWS_REGION", "us-east-1")

# Environment-specific overrides
import_config "#{config_env()}.exs"
```

```elixir
# config/dev.exs
import Config

config :my_app, MyApp.Buckets.Cloud,
  adapter: Buckets.Adapters.Volume,
  bucket: "priv/uploads/dev",
  base_url: "http://localhost:4000/uploads"
```

```elixir
# config/prod.exs
import Config

config :my_app, MyApp.Buckets.Cloud,
  bucket: System.get_env("S3_BUCKET", "my-app-prod"),
  region: System.get_env("AWS_REGION", "us-east-1")
```

```elixir
# In your Resource
defmodule MyApp.Users.User do
  use Ash.Resource,
    domain: MyApp.Users,
    extensions: [AshFormBuilder]

  attributes do
    uuid_primary_key :id
    attribute :name, :string
    attribute :avatar_path, :string
  end

  actions do
    create :create do
      accept [:name]
      argument :avatar, :string, allow_nil?: true
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
        accept: ~w(.jpg .jpeg .png),
        bucket_name: "users/avatars"  # ← Organized storage
      ]
    end
  end
end
```

## Cleanup & Lifecycle Policies

### S3 Lifecycle Rules

Configure in AWS Console to automatically:
- Delete incomplete uploads after 7 days
- Move old files to Glacier after 90 days
- Delete all files after 1 year

### Manual Cleanup Task

```elixir
defmodule MyApp.Tasks.CleanupOrphanedFiles do
  @moduledoc """
  Delete files from storage that no longer exist in database.
  """
  
  def run do
    # Get all paths from database
    db_paths = 
      MyApp.Users.User
      |> Ash.Query.select([:avatar_path])
      |> Ash.read!()
      |> Enum.map(& &1.avatar_path)
      |> MapSet.new()
    
    # List all files in storage
    storage_paths = list_all_files_in_storage()
    
    # Find orphaned files
    orphaned = Enum.reject(storage_paths, &MapSet.member?(db_paths, &1))
    
    # Delete orphaned files
    Enum.each(orphaned, &delete_file(&1))
    
    {:ok, length(orphaned)}
  end
end
```

## Security Considerations

### 1. Access Control

```elixir
# S3 Bucket Policy (restrict to your app)
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::ACCOUNT_ID:role/your-app-role"
      },
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::your-bucket",
        "arn:aws:s3:::your-bucket/*"
      ]
    }
  ]
}
```

### 2. Signed URLs for Private Files

```elixir
# Generate time-limited access URL
{:ok, signed_url} = 
  MyApp.Buckets.Cloud
  |> Buckets.Object.from_path(path)
  |> Buckets.Cloud.url(expires_in: 3600)  # 1 hour
```

### 3. File Type Validation

```elixir
field :avatar do
  type :file_upload
  opts upload: [
    cloud: MyApp.Cloud,
    accept: ~w(image/jpeg image/png image/gif),  # MIME types
    max_file_size: 5_000_000
  ]
end
```

## Monitoring & Metrics

### Track Upload Statistics

```elixir
defmodule MyApp.FileUploadMetrics do
  def record_upload(size, type, duration_ms) do
    :telemetry.execute(
      [:file_upload, :complete],
      %{size: size, duration_ms: duration_ms},
      %{type: type}
    )
  end
end
```

### Set Up Alerts

Monitor:
- Failed uploads (sudden increase = problem)
- Storage growth rate
- Upload latency
- Delete failures

## Troubleshooting

### Files Not Uploading

**Check:**
1. Cloud module configured correctly
2. Bucket exists and is accessible
3. Credentials are valid
4. Network connectivity (for S3/GCS)

### Files Not Deleting

**Check:**
1. Cloud module has delete permissions
2. File path is correct
3. Object exists in bucket
4. Check logs for error messages

### Slow Uploads

**Solutions:**
1. Use CDN (CloudFront for S3)
2. Enable multipart uploads for large files
3. Choose region closer to users
4. Consider direct-to-S3 uploads

## Cost Optimization

### 1. Choose Right Storage Class

- **Standard**: Frequently accessed files
- **Infrequent Access**: Backups, archives
- **Glacier**: Long-term retention

### 2. Enable Compression

```elixir
# Compress images before upload
{:ok, compressed} = 
  Image.open(path)
  |> Image.resize({800, 800})
  |> Image.write(temp_path)
```

### 3. Set Retention Policies

Automatically delete old files to reduce storage costs.

### 4. Use CDN Caching

Cache frequently accessed files at edge locations.
