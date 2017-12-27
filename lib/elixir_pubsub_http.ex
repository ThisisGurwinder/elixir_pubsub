defmodule ElixirPubsubHttp do
    use Application

    def start(_type, _args) do
        import Supervisor.Spec, warn: false

        web_config = [ip: {127, 0, 0, 1},
                        port: 8080,
                        dispatch: []]
        
        children = [
            worker(:webmachine_mochiweb, [web_config],
                    function: :start,
                    modules: [:mochiweb_socket_server])
        ]

        opts = [strategy: :one_for_one, name: ElixirPubsubHttp.Supervisor]
        Supervisor.start_link(children, opts)
    end
end