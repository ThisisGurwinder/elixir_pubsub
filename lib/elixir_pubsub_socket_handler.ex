defmodule ElixirPubsubSocketHandler do
    @behaviour :cowboy_websocket

    def init(req, _state) do
        {:ok, cpid} = init_long_lived()
        {:cowboy_websocket, req, %{:connection => cpid}}
    end

    def terminate(_reason, _req, _state)  do 
        :ok
    end

    def websocket_handle({:text, _content}, req, %{:connection => nil}) do
        newState = %{:connection => :exist}
        {:reply, {:text, "NIL"}, req, newState}
    end

    def websocket_handle({:text, _content}, req, state = %{:connection => :exist}) do
        {:reply, {:text, "exist"}, req, state}
    end

    def websocket_handle(_frame, _req, state) do 
        {:ok, state}
    end

    def websocket_info(_info, _req, state)  do
        {:ok, state}
    end

    def create_connection(:permanent) do
        ElixirPubsubConnection.Supervisor.start_connection(self(), :permanent, nil)
    end

    def init_long_lived do
        create_connection(:permanent)
    end
end