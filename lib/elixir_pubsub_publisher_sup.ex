defmodule ElixirPubsubPublisher.Supervisor do
    use Supervisor

    def start_link do
        Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
    end

    def start_worker(args) do
        Supervisor.start_child(__MODULE__, [args])
    end

    def init(:ok) do
        children = [
            worker(ElixirPubsubPublisher, [])
        ]

        supervise(children, strategy: :simple_one_for_one)
    end
end