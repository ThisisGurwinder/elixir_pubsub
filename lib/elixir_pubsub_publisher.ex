defmodule ElixirPubsubPublisher do
    use GenServer

    def start_link(channel, user_id, from) do
        opts = []
        GenServer.start_link(__MODULE__, [channel, user_id, from], opts)
    end

    def start(channel, user_id, from) do
        opts = []
        GenServer.start(__MODULE__, [channel, user_id, from], opts)
    end

    def stop(pid) do
        GenServer.call(pid, :stop, :infinity)
    end

    def init([channel, user_id, from]) do
        :erlang.monitor(:process, from)
        {:ok, %{:user_id => user_id, :channel => channel, :already_authorized => false }}
    end

    def handle_info({'DOWN', _ref, :process, _pid, _}, state) do
        {:stop, :shutdown, state}
    end
    def handle_info(:shutdown, state) do
        {:stop, :shutdown, state}
    end

    def handle_call({:publish, message}, _from, %{:channel => channel, :user_id => user_id, :already_authorized => already_authorized} = state) do
        case already_authorized do
            :true ->
        #         GenServer.cast(:elixir_pubsub_router, {:publish, message, :channel, channel})
                {:reply, :ok, state}
            _ ->
                # case can_publish(user_id, channel) do
        #             :true ->
        #                 GenServer.cast(:elixir_pubsub_router, {:publish, message, :channel, channel})
        #                 {:reply, :ok, Map.merge(state, %{:already_authorized = true})}
        #             error ->
                        {:reply, {:error, "error"}, state}
        #         end
        # {:reply, :ok , state}
        end
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

    def terminate(_reason, _state) do
        :ok
    end

    def code_change(_oldVsn, state, _extra) do
        {:ok, state}
    end

    def publish(publisher_pid, message) do
        GenServer.call(publisher_pid, {:publish, message})
    end

    def update_user(publisher_pid, user_id) do
        GenServer.cast(publisher_pid, {:update_user, user_id})
    end

    def can_publish(user_id, channel) do
        case Application.get_env(:ridhm_pubsub, :publish_authorization) do
            :undefined -> :true
            {:ok, auth_config} ->
                ElixirPubsubAuthorization.check_authorization(user_id, channel, auth_config)
        end
    end
end