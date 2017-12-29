defmodule ElixirPubsubConnection do
   use GenServer

   def start_link(from, type) do
        GenServer.start_link(__MODULE__, [from, type])
   end 

   def start(from, type) do
        GenServer.start(__MODULE__, [from, type])
   end

   def init([from, :permanent]) do
        Process.flag :trap_exit, true
        {:ok, %{
            :publishers => :dict.new(),
            :subscribers => :dict.new(),
            :transport => from,
            :user_id => :anonymous,
            :transport_state => :permanent,
            :buffer => [],
            :timer => :erlang.start_timer(1000000, self(), :trigger)
        }}
   end

   def handle_cast({:process_message, message}, %{:timer => timer, :transport_state => ts} = state) do
        timer2 = case ts do
                    :permanent -> :undefined
                    _ -> reset_timer(timer)
                end
        _state_new = case JSEX.decode message do
                        {:ok, parsed_message} -> process_message(:lists.keysort(1, message), state)
                        {:error, :badarg} -> send self(), {:just_send, "BAD ARGUMENT" }
                end
        {:noreply, Map.merge(state, %{:timer => timer2})}
    end
    def handle_cast(_message, state) do
        send self(), "UNKNOWN CAST"
        {:noreply, state}
    end

    def handle_info({:just_send, message}, %{:transport => transport, :buffer => buffer, :transport_state => tstate} = state) do
        new_buffer = send_transport(transport, {:message, message}, buffer, tstate)
        {:noreply, Map.merge(state, %{:buffer => new_buffer})}
    end
    def handle_info(info, state) do
        {:stop, {:unhandled_message, info}, state}
    end

    def process_message([{"subscribe", channel}], %{:subscribers => subscribers, :user_id => UserId} = state ) do
        new_subs = case :dict.find(channel, subscribers) do
                        error ->
                            {:ok, subscriberPid} = elixir_pubsub_subscriber.Supervisor.start_child([channel, userid, self()])
                            case elixir_pubsub_subscriber.subscribe(subscriberPid) do
                                :ok -> :dict.store(channel, subscriberPid, subscribers)
                                        send self(), {:just_send, "Subscribed To Channel #{inspect(channel)} and channels #{inspect(subscribers)}"}
                                {:error, error} -> send self(), {just_send, error}
                                                subscribers
                    end
        Map.merge(state, %{:subscribers => new_subs})
    end
    def process_message(_message, state) do
        send self(), {:just_send, "Unknown message received"}
        state
    end

    def reset_timer(timer) do
        case timer do
            :undefined ->
                :undefined;
            timer_ref ->
                case :erlang.cancel_timer(timer_ref) do
                    :false -> :erlang.start_timer(100000, self(), :trigger)
                    _ -> :erlang.start_timer(100000, self(), :trigger)
                end
        end
    end
    
    def send_transport(transport, {:message, message}, [], :permanent) do
        send transport, {:text, message}
        []
    end
    def send_transport(transport, {:message, message}, buffer, :temporary) do
        flush_buffer(transport, buffer++[message])
        []
    end
    def send_transport(_transport, {:message, message}, buffer, :hiatus) do
        buffer++[message]
    end

    def flush_buffer(transport, messages) do
        send transport, {:list, messages}
    end

    def timer_status(%{:timer => timer}) do
        :erlang.read_timer(timer)
    end
end