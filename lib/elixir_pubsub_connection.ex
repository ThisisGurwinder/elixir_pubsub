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
            :user_data => [],
            :transport_state => :permanent,
            :buffer => [],
            :timer => :erlang.start_timer(1000000000, self(), :trigger)
        }}
   end

   def handle_cast({:process_message, message}, %{:timer => timer, :transport_state => ts} = state) do
        timer2 = case ts do
                    :permanent -> :undefined
                    _ -> reset_timer(timer)
            end
        try do
            parsed_message = Poison.Parser.parse!(message)
            process_message(parsed_message, state)
        rescue
            error -> send self(), {:just_send, "BAD ARGUMENT #{inspect(error)}" }
        end
        {:noreply, state}
    end
    def handle_cast(_message, state) do
        send self(), "UNKNOWN CAST"
        {:noreply, state}
    end

    def handle_info({:received_message, message}, %{:transport => transport, :buffer => buffer, :transport_state => tstate} = state) do
        new_buffer = send_transport(transport, {:message, message}, buffer, tstate)
        {:noreply, Map.merge(state, %{:buffer => new_buffer})}
    end
    def handle_info({:just_send, message}, %{:transport => transport, :buffer => buffer, :transport_state => tstate} = state) do
        new_buffer = send_transport(transport, {:message, message}, buffer, tstate)
        {:noreply, Map.merge(state, %{:buffer => new_buffer})}
    end
    def handle_info(info, state) do
        {:stop, {:unhandled_message, info}, state}
    end

    def process_message(%{"subscribe" => channel}, %{:subscribers => subscribers, :user_id => userid} = state ) do
        new_subs = case :dict.find(channel, subscribers) do
                        {:ok, _} -> subscribers;
                        error ->
                            {:ok, subscriberPid} = ElixirPubsubSubscriber.Supervisor.start_child([channel, userid, self()])
                            case ElixirPubsubSubscriber.subscribe(subscriberPid) do
                                :ok -> :dict.store(channel, subscriberPid, subscribers)
                                        send self(), {:just_send, "Subscribed To Channel #{inspect(channel)} and channels #{inspect(subscribers)}"}
                                {:error, error} -> send self(), {:just_send, error}
                                                subscribers
                        
                        end
                end
        Map.merge(state, %{:subscribers => new_subs})
    end
    def process_message(%{"channel" => channel, "publish" => message}, %{:publishers => publishers, :user_id => user_id, :user_data => user_data } = state) do
        {:ok, complete_message } = Poison.encode(%{
            :type => "message",
            :message => message,
            :channel => channel,
            :user_id => user_id,
            :user_data => user_data
        }) 
        new_pubs = case :dict.find(channel, publishers) do
                            {:ok, publisher_pid} ->
                                publish(publisher_pid, complete_message)
                                publishers
                            :error ->
                                {:ok, publisher_pid} = ElixirPubsubPublisher.Supervisor.start_child([channel, user_id, self()])
                                publish(publisher_pid, complete_message)
                                :dict.store(channel, publisher_pid, publishers)
                    end
        Map.merge(state, %{:publishers => new_pubs})
    end
    def process_message(%{"presence" => channel}, %{:subscribers => subscribers}) do
        case Application.get_env(:elixir_pubsub, :presence) do
            {:ok, :true} ->
                case :dict.find(channel, subscribers) do
                    :error -> send self(), "Cannot ask for presence when not subscribed to channel"
                    {:ok, _} ->
                        user_subs = ElixirPubsubPresence.presence(channel)
                        send self(), {:presence_response,
                            Poison.encode(%{ :type => "presence",
                                :subscribers => user_subs,
                                :channel => channel
                            })}
                end
            _ ->
                send self(), {:just_send, "presence is disabled"}
        end
    end
    def process_message(message, state) do
        send self(), {:just_send, message}
        state
    end

    def publish(publisher_pid, complete_message) do
        case GenServer.call(publisher_pid, {:publish, complete_message}) do
            :ok -> 
                send self(), {:just_send, "Publish this message #{inspect(complete_message)}" }
                :ok
            {:error, error} -> send self(), {:just_send, error}
        end
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