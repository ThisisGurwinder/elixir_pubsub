defmodule ElixirPubsubConnection.Supervisor do
    defstruct parent: nil
    def start() do
        IO.puts "About to start Elixir Pubsub Connection Sup"
        pid = init(self())
        IO.puts "Got the PS #{inspect(pid)} Successfully"
        :erlang.register(__MODULE__, pid)
        {:ok, pid}
    end 
  
    def start_connection(from, type, token) do
        send __MODULE__, {__MODULE__, :start_connection, from, type, token}
    end
 
    def init(parent) do
        :ets.new(:elixir_pubsub_conn_bypid, [:set, :public, :named_table])
        :ets.new(:elixir_pubsub_conn_bytok, [:set, :public, :named_table])
        Process.flag :trap_exit, true
        IO.puts "About to spawn Loop"
        loop(%ElixirPubsubConnection.Supervisor{parent: parent}, 0)
    end

    def loop(%ElixirPubsubConnection.Supervisor{parent: parent} = state, curConns) do
        IO.puts "Started Successfully Supervisor :PubsubConnection" 
        receive do
            {__MODULE__, :start_connection, from, type, token} ->
                case ElixirPubsubConnection.start_link(from, type) do
                    {:ok, pid} ->
                        IO.puts "Got the response from ElixirPubsubConnection :ok, #{inspect(pid)}"
                        send from, {:ok, pid}
                        case type do
                            :itermittent ->
                                :ets.insert(:elixir_pubsub_conn_bypid, {token, pid})
                                :ets.insert(:elixir_pubsub_conn_bytok, {pid, token})
                            _ ->
                                :ok
                        end
                        loop(state, curConns+1)
                    _ ->
                        send from, self()
                        loop(state, curConns)
                end;
            {'EXIT', parent, reason} ->
                exit(reason)
            {'EXIT', pid, reason} ->
                report_error(pid, reason)
                case :ets.lookup(:elixir_pubsub_conn_bypid, pid) do
                    [{_, token}] ->
                        :ets.delete(:elixir_pubsub_conn_bypid, pid)
                        :ets.delete(:elixir_pubsub_conn_bytok, token)
                    [] ->
                        :ok
                end
                loop(state, curConns-1)
            {:system, from, msg} ->
                :sys.handle_system_msg(msg, from, parent, __MODULE__, [],
                                            {state, curConns})
            {'$gen_call', {to, tag}, :which_children} ->
                children = :ets.tab2list(:elixir_pubsub_conn_bypid)
                send to, {tag, children}
                loop(state, curConns)
            {'$gen_call', {to, tag}, :count_children} ->
                counts = [{:supervisors, 0}, {:workers, curConns}]
                counts2 = [{:specs, 1}, {:active, curConns} | counts]
                send to , {tag, counts2}
                loop(state, curConns)
            msg ->
                IO.puts "Unknown message received #{inspect(msg)}"
        end
    end

    def system_continue(_, _, {state, curConns}) do
        loop(state, curConns)
    end

    def system_terminate(reason, _, _, _) do
        exit(reason)
    end

    def system_code_change(misc, _, _, _) do
        {:ok, misc}
    end

    def report_normal(_, :normal) do
        :ok
    end
    def report_normal(_, :shutdown) do
        :ok
    end
    def report_error(_, {:shutdown, _}) do
        :ok
    end
    def report_error(ref, reason) do
        IO.puts "Exited with ref #{inspect(ref)} and reason #{inspect(reason)}"
    end
end