defmodule ElixirPubsub do
    def start() do
        ElixirPubsubConnection.Supervisor.start_link()
    end

    ElixirPubsub.start()
end