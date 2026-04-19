defmodule AshFormBuilder.Test.MockCloud do
  @moduledoc """
  Minimal cloud mock for file upload tests. Copies to System.tmp_dir! and returns
  the relative destination path so tests can assert on the stored location.
  """

  @tmp_dir Path.join(System.tmp_dir!(), "ash_form_builder_test_uploads")

  def insert(%Buckets.Object{} = object, _opts \\ []) do
    dest_path = "uploads/#{object.uuid}/#{object.filename}"
    full_dest = Path.join(@tmp_dir, dest_path)

    File.mkdir_p!(Path.dirname(full_dest))

    case object.data do
      {:file, src} -> File.cp!(src, full_dest)
      {:data, data} -> File.write!(full_dest, data)
      nil -> :ok
    end

    stored = %{
      object
      | location: %Buckets.Location{path: dest_path, config: []},
        stored?: true
    }

    {:ok, stored}
  end
end

defmodule AshFormBuilder.Test.UploadResources do
  @moduledoc false

  # ---------------------------------------------------------------------------
  # UserProfile — resource with a file_upload argument
  # ---------------------------------------------------------------------------

  defmodule UserProfile do
    @moduledoc false
    use Ash.Resource,
      domain: AshFormBuilder.Test.UploadResources.Domain,
      data_layer: Ash.DataLayer.Ets,
      extensions: [AshFormBuilder]

    ets do
      private?(true)
    end

    attributes do
      uuid_primary_key(:id)
      attribute(:name, :string, allow_nil?: false, public?: true)
      attribute(:avatar_path, :string, public?: true)
    end

    actions do
      defaults([:read, :destroy])

      create :create do
        accept([:name])
        argument(:avatar, :string, allow_nil?: true)

        change(fn changeset, _ ->
          case Ash.Changeset.get_argument(changeset, :avatar) do
            nil -> changeset
            path -> Ash.Changeset.change_attribute(changeset, :avatar_path, path)
          end
        end)
      end
    end

    form do
      action(:create)
      submit_label("Save profile")

      field :name do
        label("Full name")
        required(true)
      end

      field :avatar do
        type(:file_upload)
        label("Profile photo")
        hint("JPEG or PNG, max 5 MB")

        opts(
          upload: [
            cloud: AshFormBuilder.Test.MockCloud,
            max_entries: 1,
            max_file_size: 5_000_000,
            accept: ~w(.jpg .jpeg .png)
          ]
        )
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Domain
  # ---------------------------------------------------------------------------

  defmodule Domain do
    @moduledoc false
    use Ash.Domain

    resources do
      resource(UserProfile)
    end
  end
end
