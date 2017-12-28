defmodule ElixirPubsubHttp do
    
    def start(_type, _args) do
        dispatch_config = build_dispatch_config
        { :ok, _ } = :cowboy.start_http(:http,
                        100,
                        [{:port, 8080}],
                        [{:env, [{:dispatch, dispatch_config}]}]
                    )
        spawn(fn -> ElixirPubsubConnection.Supervisor.start() end)
    end

    def build_dispatch_config do
        :cowboy_router.compile([
            { :_,
                [
                    {"/", ElixirPubsubHttpDefault, []},
                    {"/ws", ElixirPubsubSocketHandler, []}
                ]}
        ])
    end
end