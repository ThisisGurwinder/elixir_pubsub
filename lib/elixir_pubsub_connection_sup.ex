defmodule ElixirPubsubConnection.Supervisor do
    defstruct parent: nil
    def start() do
        IO.puts "Starting Elixir Pubsub Connection"
        spawn_link(__MODULE__, :init, [self()])
    end 

    def start_connection(from, type, token) do
        send __MODULE__, {__MODULE__, :start_connection, from, type, token}
        receive do Ret -> Ret end
    end

    def init(parent) do
        # :ets.new(:elixir_pubsub_conn_bypid, [:set, :public, :named_table])
        # :ets.new(:elixir_pubsub_conn_bytok, [:set, :public, :named_table])
        # Process.flag :trap_exit, true
        loop(%ElixirPubsubConnection.Supervisor{parent: parent}, 0)
    end

    def loop(%ElixirPubsubConnection.Supervisor{parent: parent} = state, curConns) do
        # IO.puts "Done"
        receive do
            {__MODULE__, :start_connection, from, type, token} ->
                IO.puts "Got the Start Connection #{inspect(from)} #{inspect(type)}"
                case ElixirPubsubConnection.start_link(from, type) do
                    {:ok, pid} ->
                        send from, {:ok, pid}
                        IO.puts "Started Elixir Pubsub Connection Supervisor"
                        loop(state, curConns+1)
                    _ ->
                        send from, {:ok, self()}
                        loop(state, curConns)
                end;
            msg ->
                # send From, self()
                IO.puts "Unknown Message Recieved #{msg}"
        end
    end
end