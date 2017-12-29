defmodule ElixirPubsubSubscriber.Supervisor do
    use Supervisor

    def start_link(_) do
        {:ok, sup} = Supervisor.start_link(__MODULE__, [], name: :supervisor)
    end
    def start_child(args) do
        Supervisor.start_child(__MODULE__, args)
    end
    def init(_) do
        {:ok, {{:one_for_one, 10, 10}, []}}
        # {:ok, {{:simple_one_for_one, 5, 10}, [
        #     {:elixir_pubsub_subscriber,
        #         {:elixir_pubsub_subscriber, :start_link, []},
        #         :temporary,
        #         :infinity,
        #         :worker,
        #         [:ridhm_pubsub_subscriber]
        #         } ]}}s
    end
end