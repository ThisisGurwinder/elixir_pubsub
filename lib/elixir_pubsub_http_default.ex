defmodule ElixirPubsubHttpDefault do
    def init(req, state) do
        handle(req, state)
    end

    def handle(request, state) do
        req = :cowboy_req.reply(
            200,
            [{"content-type", "application/text"}],
            "Default Response ...",
            request
        )        
    {:ok, req, state}
    end

    def terminate(_reason, _request, _state) do
        :ok
    end
end