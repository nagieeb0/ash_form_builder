defmodule AshFormBuilder.Test.Endpoint do
  @moduledoc false

  @session_options [
    store: :cookie,
    key: "_afb_test",
    signing_salt: "signing_salt_test"
  ]

  use Phoenix.Endpoint, otp_app: :ash_form_builder

  socket("/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: @session_options]],
    longpoll: [connect_info: [session: @session_options]]
  )

  plug(Plug.RequestId)
  plug(Plug.Telemetry, event_prefix: [:phoenix, :endpoint])
  plug(Plug.Parsers, parsers: [:urlencoded, :multipart], pass: ["*/*"])
  plug(Plug.Session, @session_options)
  plug(AshFormBuilder.Test.Router)
end
