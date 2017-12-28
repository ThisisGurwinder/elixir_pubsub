defmodule ElixirPubsubConnection.Supervisor do
    # defstruct parent: nil
    def start_link(_) do
        spawn_link(__MODULE__, :init, [self])
    end 

    def start_connection(_From, _Type, _Token) do
        # send __MODULE__, {__MODULE__, start_connection, From, Type, Token}
        {ok, self()}
    end

    def init(_Parent) do
        # :ets.new(:elixir_pubsub_conn_bypid, [:set, :public, :named_table])
        # :ets.new(:elixir_pubsub_conn_bytok, [:set, :public, :named_table])
        # Process.flag :trap_exit, true
        loop(%__MODULE__{parent = Parent}, 0)
    end

    def loop(State = %__MODULE__{parent = Parent}, CurConns) do
        # IO.puts "Done"
        receive do
            {__MODULE__, start_connection, From, Type, Token} ->
                send From, self()
                IO.puts "Started Elixir Pubsub Connection Supervisor"
                loop(State, CurConns+1)
            Msg ->
                send From, self()
                IO.puts "Unknown Message Recieved #{Msg}"
        end
    end
end