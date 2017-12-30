defmodule ElixirPubsubPublisher.Supervisor do
    use Supervisor

    def start_link do
        IO.puts "Started Start_lInk"
        Supervisor.start_link(__MODULE__, [], name: :elixir_pubsub_publisher_supervisor)
    end
    def start_child(args) do
        Supervisor.start_child(:elixir_pubsub_publisher_supervisor, [args])
    end
    def init(_) do
        children = [
            worker(ElixirPubsubPublisher, [])
        ]

        supervise(children, strategy: :simple_one_for_one)
    end
end