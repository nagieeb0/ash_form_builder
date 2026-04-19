defmodule AshFormBuilder.Test.Resources do
  @moduledoc "Shared Ash test resources for the AshFormBuilder test suite."

  # ---------------------------------------------------------------------------
  # Tag — simple nested resource
  # ---------------------------------------------------------------------------

  defmodule Tag do
    use Ash.Resource,
      domain: AshFormBuilder.Test.Resources.Blog,
      data_layer: Ash.DataLayer.Ets

    ets do
      private?(true)
    end

    attributes do
      uuid_primary_key(:id)
      attribute(:name, :string, allow_nil?: false, public?: true)
      attribute(:post_id, :uuid, public?: true)
    end

    actions do
      defaults([:read, :destroy, create: [:name], update: [:name]])
    end
  end

  # ---------------------------------------------------------------------------
  # Post — fully explicit DSL declarations
  # ---------------------------------------------------------------------------

  defmodule Post do
    use Ash.Resource,
      domain: AshFormBuilder.Test.Resources.Blog,
      data_layer: Ash.DataLayer.Ets,
      extensions: [AshFormBuilder]

    ets do
      private?(true)
    end

    attributes do
      uuid_primary_key(:id)
      attribute(:title, :string, allow_nil?: false, public?: true)
      attribute(:body, :string, public?: true)
      attribute(:status, :atom, constraints: [one_of: [:draft, :published]], public?: true)
      attribute(:published, :boolean, default: false, public?: true)
    end

    relationships do
      has_many(:tags, Tag)
    end

    actions do
      defaults([
        :read,
        :destroy,
        create: [:title, :body, :status, :published],
        update: [:title, :body]
      ])
    end

    form do
      action(:create)
      submit_label("Publish post")
      wrapper_class("post-form-fields")

      field :title do
        label("Title")
        placeholder("Enter a title…")
        required(true)
      end

      field :body do
        label("Body")
        type(:textarea)
        hint("Markdown is supported")
      end

      field :status do
        label("Status")
        type(:select)
        options([{"Draft", :draft}, {"Published", :published}])
      end

      field :published do
        label("Publicly visible?")
        type(:checkbox)
      end

      nested :tags do
        label("Tags")
        cardinality(:many)
        add_label("Add tag")
        remove_label("Remove")
        create_action(:create)
        update_action(:update)

        field :name do
          label("Tag name")
          required(true)
        end
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Article — zero-config form: only `action :create`, no explicit fields.
  # All fields are auto-inferred from the action's accept list.
  # ---------------------------------------------------------------------------

  defmodule Article do
    use Ash.Resource,
      domain: AshFormBuilder.Test.Resources.Blog,
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
      attribute(:view_count, :integer, default: 0, public?: true)

      attribute(:status, :atom,
        constraints: [one_of: [:draft, :review, :published]],
        public?: true
      )
    end

    actions do
      defaults([
        :read,
        :destroy,
        create: [:title, :body, :published, :view_count, :status],
        update: [:title, :body]
      ])
    end

    form do
      # Intentionally empty — all fields are auto-inferred
      action(:create)
    end
  end

  # ---------------------------------------------------------------------------
  # Review — partial override: some fields explicit, rest inferred
  # ---------------------------------------------------------------------------

  defmodule Review do
    use Ash.Resource,
      domain: AshFormBuilder.Test.Resources.Blog,
      data_layer: Ash.DataLayer.Ets,
      extensions: [AshFormBuilder]

    ets do
      private?(true)
    end

    attributes do
      uuid_primary_key(:id)
      attribute(:title, :string, allow_nil?: false, public?: true)
      attribute(:body, :string, public?: true)
      attribute(:rating, :integer, public?: true)
      attribute(:approved, :boolean, default: false, public?: true)
    end

    actions do
      defaults([
        :read,
        :destroy,
        create: [:title, :body, :rating, :approved],
        update: [:title, :body]
      ])
    end

    form do
      action(:create)
      # Only override body — title, rating, approved are inferred
      field :body do
        label("Full Review")
        type(:textarea)
        hint("Be as detailed as possible")
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Category — for many_to_many relationship testing with creatable support
  # ---------------------------------------------------------------------------

  defmodule Category do
    use Ash.Resource,
      domain: AshFormBuilder.Test.Resources.Blog,
      data_layer: Ash.DataLayer.Ets

    ets do
      private?(true)
    end

    attributes do
      uuid_primary_key(:id)
      attribute(:name, :string, allow_nil?: false, public?: true)
      attribute(:description, :string, public?: true)
    end

    actions do
      defaults([:read, :destroy, create: [:name, :description], update: [:name, :description]])
    end
  end

  # ---------------------------------------------------------------------------
  # BlogPost — many_to_many with Categories (creatable support)
  # ---------------------------------------------------------------------------

  defmodule BlogPost do
    use Ash.Resource,
      domain: AshFormBuilder.Test.Resources.Blog,
      data_layer: Ash.DataLayer.Ets,
      extensions: [AshFormBuilder]

    ets do
      private?(true)
    end

    attributes do
      uuid_primary_key(:id)
      attribute(:title, :string, allow_nil?: false, public?: true)
      attribute(:content, :string, public?: true)
    end

    relationships do
      many_to_many(:categories, Category) do
        through BlogPostCategory
        source_attribute_on_join_resource(:blog_post_id)
        destination_attribute_on_join_resource(:category_id)
      end
    end

    actions do
      defaults([
        :read,
        :destroy
      ])

      create :create do
        accept([:title, :content])
        manage_relationship(:categories, :categories, type: :append_and_remove)
      end

      update :update do
        accept([:title, :content])
        manage_relationship(:categories, :categories, type: :append_and_remove)
      end
    end

    form do
      action(:create)

      field :title do
        label("Post Title")
        placeholder("Enter post title")
        required(true)
      end

      field :content do
        label("Content")
        type(:textarea)
      end

      field :categories do
        type(:multiselect_combobox)
        label("Categories")
        placeholder("Search or create categories")

        opts [
          creatable: true,
          create_action: :create,
          create_label: "Create \"",
          search_event: "search_categories",
          debounce: 300,
          label_key: :name,
          value_key: :id
        ]
      end
    end
  end

  # ---------------------------------------------------------------------------
  # BlogPostCategory — Join resource
  # ---------------------------------------------------------------------------

  defmodule BlogPostCategory do
    use Ash.Resource,
      domain: AshFormBuilder.Test.Resources.Blog,
      data_layer: Ash.DataLayer.Ets

    ets do
      private?(true)
    end

    attributes do
      uuid_primary_key(:id)
      attribute(:blog_post_id, :uuid, allow_nil?: false, public?: true)
      attribute(:category_id, :uuid, allow_nil?: false, public?: true)
    end

    relationships do
      belongs_to(:blog_post, BlogPost)
      belongs_to(:category, Category)
    end
  end

  # ---------------------------------------------------------------------------
  # Blog domain
  # ---------------------------------------------------------------------------

  defmodule Blog do
    use Ash.Domain

    resources do
      resource(Tag)
      resource(Post)
      resource(Article)
      resource(Review)
      resource(Category)
      resource(BlogPost)
      resource(BlogPostCategory)
    end
  end
end
