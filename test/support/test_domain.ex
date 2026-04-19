defmodule AshFormBuilder.Test.Domain.Specialty do
  @moduledoc false
  use Ash.Resource,
    domain: AshFormBuilder.Test.Domain,
    data_layer: Ash.DataLayer.Ets

  ets do
    private?(true)
  end

  attributes do
    uuid_primary_key(:id)
    attribute(:name, :string, allow_nil?: false, public?: true)
    attribute(:code, :string, public?: true)
  end

  actions do
    defaults([:read, :destroy, create: [:name, :code], update: [:name, :code]])
  end
end

defmodule AshFormBuilder.Test.Domain.ClinicSpecialty do
  @moduledoc false
  use Ash.Resource,
    domain: AshFormBuilder.Test.Domain,
    data_layer: Ash.DataLayer.Ets

  ets do
    private?(true)
  end

  attributes do
    uuid_primary_key(:id)
    attribute(:clinic_id, :uuid, allow_nil?: false, public?: true)
    attribute(:specialty_id, :uuid, allow_nil?: false, public?: true)
  end

  actions do
    defaults([:read, :destroy])
  end
end

defmodule AshFormBuilder.Test.Domain.Subtask do
  @moduledoc false
  use Ash.Resource,
    domain: AshFormBuilder.Test.Domain,
    data_layer: Ash.DataLayer.Ets

  ets do
    private?(true)
  end

  attributes do
    uuid_primary_key(:id)
    attribute(:title, :string, allow_nil?: false, public?: true)
  end

  relationships do
    belongs_to(:clinic, AshFormBuilder.Test.Domain.Clinic, allow_nil?: false, public?: true)
  end

  actions do
    defaults([:read, :destroy])

    create :create do
      accept([:title])
    end

    update :update do
      accept([:title])
    end
  end
end

defmodule AshFormBuilder.Test.Domain.Clinic do
  @moduledoc false
  use Ash.Resource,
    domain: AshFormBuilder.Test.Domain,
    data_layer: Ash.DataLayer.Ets,
    extensions: [AshFormBuilder]

  ets do
    private?(true)
  end

  attributes do
    uuid_primary_key(:id)
    attribute(:name, :string, allow_nil?: false, public?: true)
    attribute(:phone, :string, public?: true)
  end

  relationships do
    many_to_many(:specialties, AshFormBuilder.Test.Domain.Specialty) do
      through(AshFormBuilder.Test.Domain.ClinicSpecialty)
      source_attribute_on_join_resource(:clinic_id)
      destination_attribute_on_join_resource(:specialty_id)
    end

    has_many(:subtasks, AshFormBuilder.Test.Domain.Subtask)
  end

  actions do
    defaults([:read, :destroy])

    create :create do
      accept([:name, :phone])
      argument(:referral_code, :string, allow_nil?: true)

      manage_relationship(:specialties, :specialties, type: :append_and_remove)
      manage_relationship(:subtasks, :subtasks, type: :create)
    end

    update :update do
      accept([:name, :phone])

      manage_relationship(:specialties, :specialties, type: :append_and_remove)
      manage_relationship(:subtasks, :subtasks, type: :create)
    end
  end

  form do
    action(:create)
    submit_label("Create clinic")

    field(:name) do
      label("Clinic name")
      placeholder("Acme Clinic")
      required(true)
    end

    field(:specialties) do
      label("Specialties (DSL)")
      type(:multiselect_combobox)

      opts(
        search_event: "search_specialties",
        debounce: 150,
        placeholder: "Search specialties…"
      )
    end

    nested(:subtasks) do
      label("Subtasks")
      cardinality(:many)
      add_label("Add subtask")
      remove_label("Remove subtask")

      field(:title) do
        label("Subtask title")
        required(true)
      end
    end
  end
end

defmodule AshFormBuilder.Test.Domain do
  @moduledoc false
  use Ash.Domain

  resources do
    resource(AshFormBuilder.Test.Domain.Clinic) do
      define(:form_to_create_clinic, action: :create)
      define(:form_to_update_clinic, action: :update)
    end

    resource(AshFormBuilder.Test.Domain.Specialty)
    resource(AshFormBuilder.Test.Domain.ClinicSpecialty)
    resource(AshFormBuilder.Test.Domain.Subtask)
  end
end
