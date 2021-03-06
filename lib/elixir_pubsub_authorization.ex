defmodule ElixirPubsubAuthorization do 
	
	def check_authorization(user_id, channel, config) do
		case :lists.keyfind(:level, 1, config) do
			{:level, :anonymous} -> :true
			{:level, :authenticated} -> check_is_authenticated(user_id)
			{:level, :ask} -> case check_is_authenticated(user_id) do
									:true -> ask_authentication(user_id, channel, config)
									error -> error
							end
			_ -> "bad value for level in config"
		end
	end

	def check_is_authenticated(user_id) when user_id == :anonymous do "needs authentication" end
	def check_is_authenticated(_) do :true end

	def ask_authentication(user_id, channel, config) do
		case :lists.keyfind(:authorization_url, 1, config) do
			:false -> "bad value for authorization_url in config"
			{:authorization_url, authorize_url} ->
				case :httpc.request(:post, {authorize_url, [],  "application/x-www-form-urlencoded", "userid="++:erlang.binary_to_list(user_id)++"&channel="++:erlang.binary_to_list(channel)}, [], []) do
					{:ok, {{_version, 200, _reason_phrase}, _headers, body}} ->
						try do
							case Poison.decode(:binary.list_to_bin(body)) do
								[{"authorized", :true}] -> :true
								[{"authorized", :false}] -> "no authorization"
								_smth -> "bad response from server on authorization"
							end
						catch 
							_ -> "malformed json from server on authentication"
					end
				end
		_ -> "bad response form server on authentication"
		end
	end
end