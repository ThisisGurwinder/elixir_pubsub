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
            :publishers => %{},
            :subscribers => %{},
            :transport => from,
            :user_id => :anonymous,
            :transport_state => :temporary,
            :buffer => [],
            :timer => :erlang.start_timer(1000000, self(), :trigger)
        }}
   end

   def handle_cast({:process_message, message}, %{:timer => timer, :transport_state => ts} = state) do
        IO.puts "Got The Cast #{inspect(message)}"
        timer2 = case ts do
                    :permanent -> :undefined
                    _ -> reset_timer(timer)
                end
        state_new = case JSEX.decode message do
                        {:ok, parsed_message} -> send self(), {:just_send, "MESSAGE PARSED" }
                        {:error, :badarg} -> send self(), {:just_send, "BAD ARGUMENT" }
                end
        {:noreply, %{:timer => timer2}}
    end
    def handle_cast(_message, _state) do
        send self(), "UNKNOWN CAST"
        {:noreply, _state}
    end

    def handle_info({:just_send, message}, %{:transport => transport, :buffer => buffer, :transport_state => tstate}) do
        new_buffer = send_transport(transport, {:message, message}, buffer, tstate)
        {:noreply, %{:buffer => new_buffer}}
    end
    def handle_info(info, state) do
        {:stop, {:unhandled_message, info}, state}
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
    
    def send_transport(transport, msg, [], :permanent) do
        send transport, {:text, msg}
    end

    def timer_status(%{:timer => timer}) do
        :erlang.read_timer(timer)
    end
end