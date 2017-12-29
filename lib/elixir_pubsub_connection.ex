defmodule ElixirPubsubConnection do
   use GenServer

   def start_link(from, type) do
        GenServer.start_link(__MODULE__, [from, type])
   end 

   def start(from, type) do
        GenServer.start(__MODULE__, [from, type])
   end

   def init([from, :permanent]) do
        IO.puts "Sending Back Response Done"
        {:ok, %{}}
   end
end