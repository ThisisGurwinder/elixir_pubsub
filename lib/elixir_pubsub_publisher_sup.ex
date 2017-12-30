defmodule ElixirPubsubPublisherSupervisor do
  use Supervisor

  # A simple module attribute that stores the supervisor name
  @name ElixirPubsubPublisherSupervisor

  def start_link(_opts) do
    IO.puts "WQErwerwerwerWER"
    Supervisor.start_link(__MODULE__, :ok, name: @name)
  end

  def start_bucket(args) do
    Supervisor.start_child(@name, [args])
  end

  def init(:ok) do
    Supervisor.init([ElixirPubsubPublisher], strategy: :simple_one_for_one)
  end
end