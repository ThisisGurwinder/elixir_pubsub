defmodule ElixirPubsubConnection do
   use GenServer

   def start_link(From, Type) do
        GenServer.start_link(__MODULE__, :init, [From, Type])
   end 

   def start(From, Type) do
        GenServer.start(__MODULE__, :init, [From, Type])
   end

   def init([from, :permanent]) do
        IO.puts "Started \n"
   end
end