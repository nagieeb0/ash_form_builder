{:ok, _} =
  Supervisor.start_link(
    [{Phoenix.PubSub, name: AshFormBuilder.Test.PubSub}],
    strategy: :one_for_one
  )

{:ok, _} = AshFormBuilder.Test.Endpoint.start_link()
ExUnit.start()
