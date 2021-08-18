defmodule ImapEx.Imap.ConnectionManager do
  @moduledoc """
  Connection manager for communication with IMAP server
  """
  use GenServer
  alias ImapEx.SSL.Socket
  alias ImapEx.Imap.Command

  @init_state %{socket: nil, tag: 1}

  # lib doesn't (at least I won't) support unsecure connection.
  @ssl_port 993

  # Default timeout is 15 seconds
  @default_timeout 15_000

  # Session name reffers to some user session
  # If 10 users are accessing library at the same time
  # Library SHOULD create 10 GenServers with name as user session identifier
  # Function generate_name/0 is available for generating GS names
  # Name is registered with {:global, TERM} to avoid othervise dynamic atom allocation

  def start(%{host: host, name: session_id}) when is_bitstring(host),
    do: GenServer.start_link(__MODULE__, %{host: host, port: @ssl_port}, name: {:global, session_id})

  def init(%{host: host, port: port}) do
    case Socket.init(host, port) do
      {:error, message} ->
        CompileError.exception(message)

      {socket, message} ->
        IO.inspect(message)
        {:ok, %{@init_state | socket: socket}}
    end
  end

  def send(name, command) when is_map(command) do
    gs_pid = get_gs_pid(name)

    GenServer.call(gs_pid, command, @default_timeout)
    # if Checker.is_request(request) do
    # else
    #   {:error, "Request is not structure."}
    # end
  end

  def handle_call(request, _, %{socket: socket, tag: tag} = state) do
    request = %{request | tag: "S_TAG#{tag}"}

    {:reply, process_call({socket, request}), %{state | tag: tag + 1}}
  end

  def handle_info(data, state) do
    IO.inspect(data, label: "Handle info ~> ")
    {:noreply, state}
  end

  def stop(pid) do
    Socket.send(pid, Command.Any.logout())
    Agent.stop(pid)
  end

  @doc """
  Returns 32 byte long url safe base64 encoded string
  """
  def generate_name(), do: "GS_#{Base.url_encode64(:crypto.strong_rand_bytes(24), padding: false)}"

  # Helpers
  defp get_gs_pid(name), do: GenServer.whereis(name)

  defp process_call({socket, command}) do
    command_imap = command |> Command.forge()

    Socket.send(socket, command_imap)
    Socket.recv(socket, command.tag)
  end
end
