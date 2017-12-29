defmodule ElixirPubsubSocketHandler do
    @behaviour :cowboy_websocket

    def init(req, state) do
        {:ok, cpid} = init_long_lived()
        :erlang.start_timer(1000, self, [])
        connection = %{ :connection => cpid }
        {:cowboy_websocket, req, connection}
    end

    def terminate(_reason, _req, _state) do
        :ok
    end

    def websocket_handle({:text, content}, req, %{:connection => cpid} = state) do
        GenServer.cast(cpid, {:process_message, content})
        {:reply, {:text, "ping"}, req, state}
    end
    def websocket_handle(_frame, _req, state) do
        {:ok, state}
    end
    
    def websocket_info({:text, message}, req, state) do
        {:reply, {:text, inspect(message)}, req, state}
    end
    def websocket_info({_timeout, _ref, _msg}, _req, state) do
        # time = time_as_string()
        # { :ok, message } = JSEX.encode(%{ time: time})
        :erlang.start_timer(1000, self, [])
        {:ok, state}
    end
    def websocket_info(_info, _req, state) do
        {:ok, state}
    end

    def create_connection(:permanent) do
        ElixirPubsubConnection.Supervisor.start_connection(self(), :permanent, nil)
        receive do ret -> ret end
    end

    def init_long_lived do
        create_connection(:permanent)
    end

    def time_as_string do
        {hh, mm, ss} = :erlang.time()
        :io_lib.format("~2.10.0B:~2.10.0B:~2.10.0B", [hh, mm, ss])
        |> :erlang.list_to_binary()
    end
end