defmodule ElixirPubsubSubscriber.Supervisor do
  use Application
  import Supervisor.Spec, warn: false

  def start() do

    children = [
      worker(ElixirPubsubSubscriber, [])
    ]

    opts = [strategy: :simple_one_for_one, name: ElixirPubsubSubscriber.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def start_child(args) do
    Supervisor.start_child(ElixirPubsubSubscriber.Supervisor, args)
  end
end