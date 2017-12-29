defmodule ElixirPubsubSocketHandler do
    @behaviour :cowboy_websocket

    def init(req, state) do
        IO.puts "About to initialize Socket"
        {:ok, cpid} = init_long_lived()
        :erlang.start_timer(1000, self, [])
        connection = %{ :connection => nil }
        {:cowboy_websocket, req, state}
    end

    def terminate(_reason, _req, _state)  do 
        :ok
    end

    def websocket_handle({:text, _content}, req, %{:connection => nil} = state) do
        {:reply, {:text, "NIL"}, req, state}
    end
    def websocket_handle({:text, data}, req, %{:connection => cpid} = state) do
        GenServer.cast(cpid, {:process_message, data})
        {:reply, {:text, "Processes"}, req, state}
    end
    def websocket_handle(_frame, req, state) do
        {:ok, state}
    end

    def websocket_info({:text, message}, req, state) do
        {:reply, {:text, inspect(message)}, req, state}
    end
    def websocket_info(_info, req, state)  do
        {:ok, state}
    end

    def create_connection(:permanent) do
        IO.puts "Inside create_connection :permanent "
        ElixirPubsubConnection.Supervisor.start_connection(self(), :permanent, nil)
        receive do ret -> ret end
    end

    def init_long_lived do
        IO.puts "Going to create_connection (permanent)"
        create_connection(:permanent)
    end
end