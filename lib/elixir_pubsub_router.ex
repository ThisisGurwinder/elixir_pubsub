defmodule ElixirPubsubRouter do
    use GenServer

    def start_link do
        opts = []
        GenServer.start_link(__MODULE__, [], name: __MODULE__)   
    end
    def start do
        opts = []
        GenServer.start(__MODULE__, [], name: __MODULE__) 
    end

    def init([]) do
        :ets.new(:router_subscribers, [:bag, :private, :named_table])
        {:ok, []}
    end

    def find(name) do
        case :ets.lookup(:router_subscribers, name) do
            [] -> :error
            items -> {:ok, items}
        end
    end

    def find_element(name, x) do
        case :ets.lookup_element(:router_subscribers, name, x) do
            [] -> :error
            items -> {:ok, items}
        end
    end


    def publish(message, channel) do
        IO.puts "Going to pass on Message in Router"
        GenServer.cast(__MODULE__, {:publish, message, :channel, channel})
    end

    def subscribe(channel, from, user_id) do
        IO.puts "How to subscribe "
        GenServer.cast(__MODULE__, {:subscribe, channel, :from, from, :user_id, user_id})
    end

    def unsubscribe(channel, from, user_id) do
        GenServer.cast(__MODULE__, {:unsubscribe, channel, :from, from, :user_id, user_id})
    end

    def unsubscribe_channels([], _from, _user_id) do
        :ok
    end
    def unsubscribe_channels([channel | channels], from, user_id) do
        GenServer.cast(__MODULE__, {:unsubscribe, channel, :from, from, :user_id, user_id})
        unsubscribe_channels(channels, from, user_id)
    end

    def broadcast(message, [pid | pids]) do
        send pid, message
        broadcast(message, pids)
    end
    def broadcast(_, []) do
        :true
    end

    def broadcast_cluster(message, [node | nodes]) do
       GenServer.cast({:RidhmPubsubRouter, node}, message)
       broadcast_cluster(message, nodes)  
    end
    def broadcast_cluster(_, []) do
        :true
    end

    def broker_publish(message, channel) do
        case ElixirPubsubBroker.Supervisor.get_broker() do
            :undefined ->
                IO.puts "Undefined Broker"
                :ok
            {_broker_type, broker} ->
                IO.puts "Broker About to publish"
                GenServer.cast(broker, {:publish, message, :channel, channel})
        end
    end

    def local_presence(channel) do
        GenServer.call(__MODULE__, {:local_presence, channel})
    end

    def handle_call({:local_presence, channel}, _from, state) do
        users_with_dupes = find_element(String.to_atom(channel), 3)
        case find_element(String.to_atom(channel), 2) do
            {:ok, users_with_dupes} -> {:reply, users_with_dupes, state}
            :error -> {:reply, [], state}
        end
    end
    def handle_call(:stop, _from, state) do
        {:stop, :normal, :ok, state}
    end
    
    def handle_cast({:publish, message, :channel, channel}, state) do
        IO.puts "Publish #{inspect(message)} Channel #{inspect(channel)}"
        case find_element(String.to_atom(channel), 2) do
            {:ok, subs} -> broadcast({:received_message, message, :channel, channel}, subs)
            :error -> IO.puts "Error Inside Handle Cast Elixir Pubsub Router . Handle Cast"
        end
        case node() do
            :nonode@nohost -> {:noreply, state}
             nodes -> broadcast_cluster({:cluster_publish, message, :channel, channel}, nodes)
                    {:noreply, state}
        end
    end
    def handle_cast({:cluster_publish, message, :channel, channel}, state) do
        case find_element(String.to_atom(channel), 2) do
            {:ok, subs} -> broadcast({:received_message, message, :channel, channel}, subs)
            :error -> IO.puts "Error Inside Handle Cast Elixir Pubsub Router . Handle Cast"
        end
        IO.puts "Cluster received message #{inspect(message)} and channel #{inspect(channel)}"
        {:noreply, state}
    end
    def handle_cast({:subscribe, channel, :from, reply_to, :user_id, user_id}, state) do
        :ets.insert(:router_subscribers, {String.to_atom(channel), reply_to, user_id})
        IO.puts "Subscribed Channel #{inspect(channel)}"
        {:noreply, state}
    end
    def handle_cast({:unsubscribe, channel, :from, reply_to, :user_id, user_id}, state) do
        :ets.delete_object(:router_subscribers, {String.to_atom(channel), reply_to, user_id})
        {:noreply, state}
    end
    def handle_cast(_message, state) do
        {:noreply, state}
    end

    def handle_info(_info, state) do
        {:stop, {:unhandled_message, _info}, state}
    end

    def terminate(_reason, _state) do
        :ok
    end

    def code_change(_oldVsn, state, _extra) do
        {:ok, state}
    end
end