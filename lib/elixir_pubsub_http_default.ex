defmodule ElixirPubsubHttpDefault do
    def init(req, state) do
        IO.puts "Default Http Response"
        handle(req, state)
    end

    def handle(request, state) do
        req = :cowboy_req.reply(
            200,
            [{"content-type", "application/text"}],
            "Default Response ...\n",
            request
        )        
    {:ok, req, state}
    end

    def terminate(_reason, _request, _state) do
        :ok
    end
end