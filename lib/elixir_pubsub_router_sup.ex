defmodule ElixirPubsubRouter.Supervisor do
  use Application
  import Supervisor.Spec, warn: false

  def start() do

    children = [
      worker(ElixirPubsubRouter, [])
    ]

    opts = [strategy: :simple_one_for_one, name: ElixirPubsubRouter.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def start_child(args) do
    Supervisor.start_child(ElixirPubsubRouter.Supervisor, args)
  end
end