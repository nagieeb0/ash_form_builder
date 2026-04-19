defmodule AshFormBuilder.Test.DslSampleResource do
  @moduledoc false
  use Ash.Resource,
    domain: AshFormBuilder.Test.DslSampleDomain,
    data_layer: Ash.DataLayer.Ets,
    extensions: [AshFormBuilder]

  ets do
    private?(true)
  end

  attributes do
    uuid_primary_key(:id)
    attribute(:title, :string, allow_nil?: false, public?: true)
    attribute(:body, :string, public?: true)
    attribute(:published, :boolean, default: false, public?: true)
  end

  actions do
    defaults([:read, :update, :destroy, create: [:title, :body, :published]])
  end

  form do
    action(:create)
    submit_label("Create Post")
    wrapper_class("space-y-4")

    field(:title) do
      label("Post Title")
      placeholder("Enter title")
      required(true)
    end

    field(:body) do
      label("Content")
      type(:textarea)
    end

    field(:published) do
      label("Publish immediately")
      type(:checkbox)
    end
  end
end

defmodule AshFormBuilder.Test.DslSampleDomain do
  @moduledoc false
  use Ash.Domain

  resources do
    resource(AshFormBuilder.Test.DslSampleResource)
  end
end
