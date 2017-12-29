defmodule ElixirPubsubSocketHandler do
    @behaviour :cowboy_websocket

    def init(req, _state) do
        cpid = spawn(fn -> init_long_lived() end)
        :erlang.start_timer(1000, self, [])
        connection = %{ :connection => cpid }
        {:cowboy_websocket, req, connection}
    end

    def terminate(_reason, _req, _state)  do 
        :ok
    end

    def websocket_handle({:text, _content}, req, %{:connection => nil} = state) do
        {:reply, {:text, "NIL"}, req, state}
    end
    def websocket_handle({:text, data}, req, %{:connection => cpid} = state) do

        GenServer.cast(cpid, {:process_message, data})
        {:ok, req, state}
    end
    def websocket_handle(_frame, req, state) do 
        {:ok, req, state}
    end

    def websocket_info({:text, message}, req, state) do
        IO.puts "Got the text response #{inspect(message)}"
        {:reply, req, state}
    end
    def websocket_info(_info, req, state)  do
        {:ok, req, state}
    end

    def create_connection(:permanent) do
        ElixirPubsubConnection.Supervisor.start_connection(self(), :permanent, nil)
        result = receive do ret -> ret end
        IO.puts "REsult Is #{inspect(result)}"
        result
    end

    def init_long_lived do
        create_connection(:permanent)
    end
end