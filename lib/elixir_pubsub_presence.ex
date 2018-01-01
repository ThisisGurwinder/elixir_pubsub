defmodule ElixirPubsubPresence do
	use GenServer

	def start_link do
		opts = []
		GenServer.start_link(__MODULE__, [], opts)
	end

	def stop(pid) do
		GenServer.call(pid, :stop, :infinity)
	end

	def init([]) do
		{:ok, []}
	end

	def handle_info(:shutdown, state) do
		{:ok, :shutdown, state}
	end

	def handle_call({:presence, channel}, _from, state) do
		{users_dup, _} = :rpc.multicall(RidhmPubsubRouter, :local_presence, [channel])
		users_sub = :sets.to_list(:sets.from_list(:lists.append(users_dup)))
		users_sub2 = :lists.delete(:anonymous, users_sub)
		users_sub3 = :lists.delete(:server, users_sub2)
		{:reply, users_sub3, state}
	end

	def handle_cast(_message, state) do
		{:noreply, state}
	end

	def terminate(_reason, _state) do
		:ok
	end

	def code_change(_oldvsn, state, _extra) do
		{:ok, state}
	end

	def presence(channel) do
		GenServer.call(__MODULE__, {:presence, channel})
	end
end