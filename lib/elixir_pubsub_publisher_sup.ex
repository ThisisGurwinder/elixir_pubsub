defmodule ElixirPubsubPublisher.Supervisor do
  use Application
  import Supervisor.Spec, warn: false

  def start(_type, _args) do

    children = [
      worker(ElixirPubsubPublisher, [])
    ]

    opts = [strategy: :simple_one_for_one, name: ElixirPubsubPublisher.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def start_child(args) do
    Supervisor.start_child(ElixirPubsubPublisher.Supervisor, args)
  end
end