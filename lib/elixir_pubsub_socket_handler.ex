defmodule ElixirPubsubSocketHandler do
    @behaviour :cowboy_websocket

    def init(req, state) do
        IO.puts "About to initialize Socket"
        # {:ok, cpid} = init_long_lived()
        :erlang.start_timer(1000, self, [])
        # _connection = %{ :connection => cpid }
        {:cowboy_websocket, req, state}
    end

    def terminate(_reason, _req, _state) do
    :ok
  end
  
    def websocket_handle({:text, content}, req, state) do
    { :ok, %{ "message" => message} } = JSEX.decode(content)

    rev = String.reverse(message)
    { :ok, reply } = JSEX.encode(%{ reply: rev})
    {:reply, {:text, reply}, req, state}
  end

  def websocket_handle(_frame, _req, state) do
    {:ok, state}
  end
  def websocket_info({_timeout, _ref, _msg}, req, state) do

    time = time_as_string()
    { :ok, message } = JSEX.encode(%{ time: time})
    :erlang.start_timer(1000, self, [])
    { :reply, {:text, message}, req, state}
  end

  def websocket_info(_info, _req, state) do
    {:ok, state}
  end

  def time_as_string do
    {hh, mm, ss} = :erlang.time()
    :io_lib.format("~2.10.0B:~2.10.0B:~2.10.0B", [hh, mm, ss])
    |> :erlang.list_to_binary()
  end

end