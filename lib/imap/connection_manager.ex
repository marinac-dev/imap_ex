defmodule ImapEx.Imap.ConnectionManager do
  @moduledoc """
  Connection manager for communication with IMAP server
  """

  use GenServer
  alias ImapEx.SSL.Socket
  alias ImapEx.Imap.Command

  # Default GenServer state
  @init_state %{socket: nil, tag: 1}

  # lib doesn't (at least I won't) support unsecure connection.
  @ssl_port 993

  # Default timeout is 15 seconds
  @default_timeout 15_000

  @doc """
  Starts GenServer with user session. \n
  Takes only one param, host url

    Example:
    iex(∞)> ConnectionManager.start("imap.gmail.com")
    {:ok, #PID<>}
  """
  def start(host) when is_bitstring(host),
    do: GenServer.start(__MODULE__, %{host: host, port: @ssl_port})

  def init(%{host: host, port: port}) do
    case Socket.init(host, port) do
      {:error, message} -> raise(message)
      {:ok, socket} -> {:ok, %{@init_state | socket: socket}}
    end
  end

  def send(pid, command) do
    # ! ToDo: Before making any IMAP requests check for command validity
    GenServer.call(pid, command, @default_timeout)
  end

  def handle_call(command, _from, %{socket: socket, tag: tag} = state) do
    {:reply, process_call({socket, command, tag + 1}), %{state | tag: tag + 1}}
  end

  def stop(pid) do
    __MODULE__.send(pid, Command.Any.logout()) |> IO.inspect()
    Agent.stop(pid)
  end

  @doc """
  Returns 32 byte long url safe base64 encoded random string
  """
  def generate_str(), do: "GS_#{Base.url_encode64(:crypto.strong_rand_bytes(24), padding: false)}"

  # Helpers

  defp process_call({socket, command, tag}) do
    %{imap_string: imap_string} = Command.forge(command, tag)

    Socket.send(socket, imap_string)
    Socket.recv(socket)
  end
end
