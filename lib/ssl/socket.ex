defmodule ImapEx.SSL.Socket do
  alias ImapEx.SSL.Core

  def init(host, port) when is_bitstring(host) and is_integer(port) do
    :ok = Core.start()
    {:ok, socket} = Core.connect(host |> to_charlist, port)
    {:ok, msg} = init_recv(socket)
    {socket, msg}
  end

  def init(host, port, opts) when is_bitstring(host) and is_integer(port) and is_list(opts) do
    :ok = Core.start()
    {:ok, socket} = Core.connect(host |> to_charlist, port, opts)
    {:ok, msg} = init_recv(socket)
    {socket, msg}
  end

  def stop() do
    case Core.stop() do
      :ok ->
        {:ok, :stopped}

      {:error, {:not_started, :ssl}} ->
        {:error, "SSL not started"}
    end
  end

  def close(socket) when is_tuple(socket) do
    :ok = Core.close(socket)
  end

  def send(socket, data) when is_tuple(socket) and is_bitstring(data) do
    case Core.send(socket, data) do
      :ok ->
        :ok

      {:error, :closed} ->
        {:error, "Connection is closed"}
    end
  end

  @doc """
  Used when IMAP initializes connection with server (response up to 64kb)
  """
  def init_recv(socket) when is_tuple(socket), do: Core.recv(socket, 0)

  @doc """
  Recieve data from socket until the end of IMAP response is reached.
  """

  def recv(socket, tag) when is_tuple(socket), do: recv(socket, "", tag)

  defp recv(socket, data, tag) do
    {:ok, new} = Core.recv(socket)

    if Regex.match?(~r/^.*#{tag}\s.*\r\n$/s, new),
      do: data <> new,
      else: recv(socket, data <> new, tag)
  end
end
