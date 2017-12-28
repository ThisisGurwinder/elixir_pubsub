defmodule ElixirPubsubSocketHandler do
    @behaviour :cowboy_websocket

    def init(req, _state) do
        IO.puts "Got the request to start Connection"
        cpid = spawn(fn -> init_long_lived() end)
        IO.puts "sending back response"
        :erlang.start_timer(1000, self, [])
        connection = %{:connection => cpid }
        {:cowboy_websocket, req, connection}
    end

    def terminate(_reason, _req, _state)  do 
        :ok
    end

    def websocket_handle({:text, _content}, req, %{:connection => nil}) do
        newState = %{:connection => :exist}
        {:reply, {:text, "NIL"}, req, newState}
    end

    def websocket_handle({:text, _content}, req, %{:connection => cpid} = state) do
        {:reply, {:text, inspect(cpid)}, req, state}
    end

    def websocket_handle(_frame, req, state) do 
        {:ok, req, state}
    end

    def websocket_info(_info, req, state)  do
        {:ok, req, state}
    end

    def create_connection(:permanent) do
        ElixirPubsubConnection.Supervisor.start_connection(self(), :permanent, nil)
    end

    def init_long_lived do
        create_connection(:permanent)
    end
end