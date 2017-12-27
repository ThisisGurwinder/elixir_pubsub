defmodule ElixirPubsubSocketHandler do
    @behaviour :cowboy_websocket

    def init(req, state) do
        IO.puts "State :: #{state} \n"
        {:cowboy_websocket, req, {}}
    end

    def terminate(_reason, _req, _state) do
        :ok
    end

    def websocket_handle({:text, _content}, req, state) do
        {:reply, {:text, "PONG"}, req, state}
    end

    def websocket_handle(_frame, _req, state) do
        {:ok, state}
    end

    def websocket_info(_info, _req, state) do
        {:ok, state}
    end
end