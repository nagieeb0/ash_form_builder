import Config

config :ash_form_builder, AshFormBuilder.Test.Endpoint,
  url: [host: "localhost", port: 4002],
  http: [ip: {127, 0, 0, 1}, port: 4002],
  server: false,
  secret_key_base: String.duplicate("abcdef0123456789", 4),
  live_view: [signing_salt: "live_view_test_salt"]
