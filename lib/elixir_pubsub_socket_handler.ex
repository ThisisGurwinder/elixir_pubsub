defmodule ElixirPubsubSocketHandler do
    @behaviour :cowboy_websocket

    def init(req, state) do
        CPid = init_long_lived(),
        {:cowboy_websocket, req, %{:connection => nil}}
    end

    def terminate(_reason, _req, _state) 
    :do :ok
    
    def websocket_handle({:text, _content}, req, state = %{:connection => nil}) do
        newState = %{:connection => "EXIST"}
        {:reply, {:text, "NIL"}, req, newState}
    end

    def websocket_handle({:text, _content}, req, state = %{:connection => _Something }) 
    :do {:reply, {:text, "EXIST"}, req, state}

    def websocket_handle(_frame, _req, state)
    :do {:ok, state}

    def websocket_info(_info, _req, state) 
    :do {:ok, state}

    def create_connection(permanent) do
        {ok, CPid} = 
    end

    def init_long_lived 
    :do create_connection(permanent)
end