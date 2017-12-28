defmodule ElixirPubsubConnection.Supervisor do
    defstruct parent: nil
    def start() do
        IO.puts "Starting Elixir Pubsub Connection"
        pid = spawn init(self())
        IO.puts "Process ID Starting #{inspect(pid)}"
    end 

    def start_connection(from, type, token) do
        IO.puts "GOing to start connection"
        send __MODULE__, {:start_connection, from, type, token}
        receive do Ret -> Ret end
    end

    def init(parent) do
        # :ets.new(:elixir_pubsub_conn_bypid, [:set, :public, :named_table])
        # :ets.new(:elixir_pubsub_conn_bytok, [:set, :public, :named_table])
        Process.flag :trap_exit, true
        loop(%ElixirPubsubConnection.Supervisor{parent: parent}, 0)
    end

    def loop(%ElixirPubsubConnection.Supervisor{parent: parent} = state, curConns) do
        receive do
            # {:start_connection, from, type, token} ->
            #     IO.puts "Got the Start Connection #{inspect(from)} #{inspect(type)}"
            #     case ElixirPubsubConnection.start_link(from, type) do
            #         {:ok, pid} ->
            #             send from, {:ok, pid}
            #             IO.puts "Started Elixir Pubsub Connection Supervisor"
            #             loop(state, curConns+1)
            #         _ ->
            #             IO.puts "Got the empty response"
            #             send from, {:ok, self()}
            #             loop(state, curConns)
            #     end;
            msg ->
                # send From, self()
                IO.puts "Unknown Message Recieved #{inspect(msg)}"
                loop(state, curConns)
        end
    end
end