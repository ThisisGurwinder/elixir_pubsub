defmodule ElixirPubsubSocketHandler do
    @behaviour :cowboy_websocket

    def init(req, state) do
        {:cowboy_websocket, req, %{:connection => nil}}
    end

    def terminate(_reason, _req, _state) do
        :ok
    end

    def websocket_handle({:text, _content}, req, state = %{:connection => nil}) do
        newState = %{:connection => "EXIST"}
        {:reply, {:text, "NIL"}, req, newState}
    end

    def websocket_handle({:text, _content}, req, state = %{:connection => _Something }) do
        {:reply, {:text, "EXIST"}, req, state}
    end

    def websocket_handle(_frame, _req, state) do
        {:ok, state}
    end

    def websocket_info(_info, _req, state) do
        {:ok, state}
    end
end