defmodule ElixirPubsubHttp do
    
    def start(_type, _args) do
        dispatch_config = build_dispatch_config
        _connection_sup_pid = spawn(fn -> ElixirPubsubConnection.Supervisor.start() end)
        ElixirPubsubPublisherSupervisor.start_link([])
        ElixirPubsubPublisherSupervisor.start_bucket(["werew", "user_id", self()])
        IO.puts "About to start http handler"
        { :ok, _ } = :cowboy.start_http(:http,
                        100,
                        [{:port, 8080}],
                        [{:env, [{:dispatch, dispatch_config}]}]
                    )
    end

    def build_dispatch_config do
        IO.puts "About to compile dispatch"
        :cowboy_router.compile([
            { :_,
                [
                    {"/", ElixirPubsubHttpDefault, []},
                    {"/ws", ElixirPubsubSocketHandler, []}
                ]}
        ])
    end
end