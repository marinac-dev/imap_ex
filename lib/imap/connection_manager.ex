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

  def start(host) when is_bitstring(host),
    do: GenServer.start_link(__MODULE__, %{host: host, port: @ssl_port})

  def init(%{host: host, port: port}) do
    case Socket.init(host, port) do
      {:error, message} ->
        raise(message)

      {socket, message} ->
        IO.inspect(message)
        {:ok, %{@init_state | socket: socket}}
    end
  end

  def send(pid, command) do
    # ! ToDo: Before making any IMAP requests check for command validity
    GenServer.call(pid, command, @default_timeout)
  end

  def handle_call(command, _from, %{socket: socket, tag: tag} = state),
    do: {:reply, process_call({socket, command, tag + 1}), %{state | tag: tag + 1}}

  def handle_info(data, state) do
    IO.inspect(data, label: "Handle info ~> ")
    {:noreply, state}
  end

  def stop(pid) do
    __MODULE__.send(pid, Command.Any.logout()) |> IO.inspect()
    Agent.stop(pid)
  end

  @doc """
  Returns 32 byte long url safe base64 encoded string
  """
  def generate_name(), do: "GS_#{Base.url_encode64(:crypto.strong_rand_bytes(24), padding: false)}"

  # Helpers

  defp process_call({socket, command, tag}) do
    command = command |> Command.forge(tag)

    Socket.send(socket, command.imap_string)
    Socket.recv(socket)
  end
end
