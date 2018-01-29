
defmodule Project2.Dist do
    def start_connection(application,server\\:error) do
      unless Node.alive?() do
        local_node_name = create_name(application,server)
        {:ok, _} = Node.start(local_node_name)
      end
      cookie = Application.get_env(application, :cookie)
      Node.set_cookie(cookie)
    end
  
    def create_name(application,server) do
      {:ok,record_ip}=:inet.getif()
     
      system = Application.get_env(application, :system, record_ip|>List.first|>Tuple.to_list|>List.first|>Tuple.to_list|>Enum.join("."))
      
      hex_value=
        case server do
        :error-> ""
        :ok->  :erlang.monotonic_time() |>
              :erlang.phash2(256) |>
              Integer.to_string(16)
        end
      String.to_atom("#{application}#{hex_value}@#{system}")
    end
  end