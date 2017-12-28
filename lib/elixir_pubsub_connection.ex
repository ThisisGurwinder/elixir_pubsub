defmodule ElixirPubsubConnection do
   use GenServer

   def start_link(From, Type) do
        GenServer.start_link(__MODULE__, [From, Type])
   end 

   def start(From, Type) do
        GenServer.start(__MODULE__, [From, Type])
   end

   def init([From, :permanent]) do
        IO.puts "Started \n"
   end
end