defmodule ElixirPubsubSubscriber do
    use GenServer

    def start_link(channel, user_id, reply_pid) do
        opts = []
        GenServer.start_link(__MODULE__, [channel, user_id, reply_pid], opts)
    end
    def start(channel, user_id, reply_pid) do
        opts = []
        GenServer.start(__MODULE__, [channel, user_id, reply_pid], opts)
    end

    def stop(pid) do
        GenServer.call(pid, :stop, :infinity)
    end

    def init([channel, user_id, reply_pid]) do
        :erlang.monitor(:process, reply_pid)
        {:ok, %{:channel => channel, :user_id => user_id, :reply_pid => reply_pid }}
    end

    def handle_info({'DOWN', _ref, :process, _pid, _}, state) do
        {:stop, :normal, state}
    end
    def handle_info({:received_message, msg, :channel, _channel}, %{:reply_pid => reply_pid} = state) do
        send reply_pid, {:received_message, msg}
        {:noreply, state}
    end
    def handle_info(:shutdown, state) do
        {:stop, :normal, state}
    end

    def handle_call(:subscribe, _from, %{:channel => channel, :user_id => user_id} = state) do
        IO.puts "Subscribe :: Channel #{inspect(channel)} and user_id #{inspect(user_id)}"
        res = maybe_subscribe(user_id, channel)
        {:reply, res, state}
    end
    def handle_call(:stop, _from, state) do
        {:stop, :normal, :ok, state}
    end

    def handle_cast({:update_user, user_id}, state) do
        {:noreply, Map.merge(state, %{:user_id => user_id})}
    end
    def handle_cast(_message, state) do
        {:noreply, state}
    end

    def subscribe(subscriber_pid) do
        GenServer.call(subscriber_pid, :subscribe)
    end
    def update_user(subscriber_pid, user_id) do
        GenServer.cast(subscriber_pid, {:update_user, user_id})
    end

    def maybe_subscribe(user_id, channel) do
        case can_subscribe(user_id, channel) do
            :true -> subscribe_in_router(channel, user_id)
                :ok
            error -> {:error, error}
        end
    end
    def can_subscribe(user_id, channel) do
        case Application.get_env(:ridhm_pubsub, :subscribe_authorization) do
            :undefined -> :true
            msg -> :true
            # {:ok, auth_config} -> ElixirPubsub.check_authorization(userid, channel, auth_config)
        end
    end
    def subscribe_in_router(channel, user_id) do
        :ok = GenServer.cast(:ridhm_pubsub_router, {:subscribe, channel, :from, self(), :user_id, user_id})
    end
end