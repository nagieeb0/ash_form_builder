defmodule AshFormBuilder.Test.Router do
  @moduledoc false
  use Phoenix.Router
  import Phoenix.LiveView.Router

  pipeline :browser do
  end

  scope "/" do
    pipe_through(:browser)

    live_session :afb_test do
      live("/clinic-form", AshFormBuilder.Test.ClinicFormLive, :index)
    end
  end
end
