defmodule ElixirPubsubPublisher.Supervisor do
    use Supervisor

    def start_link() do
        {:ok, sup} = Supervisor.start_link(__MODULE__, [], name: :ElixirPubsubPublisherSupervisor)
    end
    def start_child(args) do
        Supervisor.start_child(__MODULE__, args)
    end
    def init(_) do
        {:ok, {{:simple_one_for_one, 10, 10}, [
            {:elixir_pubsub_publisher,
                {:elixir_pubsub_publisher, :start_link, []},
                :temporary,
                :infinity,
                :worker,
                [:elixir_pubsub_publisher]
                } ]}}
    end
end