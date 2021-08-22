defmodule ImapEx.SSL.Socket do
  alias ImapEx.SSL.Core

  def init(host, port) when is_bitstring(host) and is_integer(port) do
    # We want SSL to either start or break
    :ok = Core.start()
    {:ok, socket} = Core.connect(host, port)
    # Immediately after the connection is established, server sends response
    Core.recv(socket, 0, 500)
    {:ok, socket}
  end

  def stop() do
    case Core.stop() do
      :ok -> {:ok, :stopped}
      {:error, {:not_started, :ssl}} -> {:error, "SSL not started"}
    end
  end

  def close(socket) when is_tuple(socket) do
    :ok = Core.close(socket)
  end

  @doc """
  Sends data to IMAP server
  Takes socket and data/command (use Command module to request commands)
  """
  def send(socket, data) when is_tuple(socket) and is_bitstring(data),
    do: socket |> Core.send(data) |> handle_send()

  def handle_send(:ok), do: :ok
  def handle_send({:error, :closed}), do: {:error, "Connection is closed"}
  def handle_send(any), do: {:error, any}

  @doc """
  Recieve data from socket until the end of IMAP response is reached.
  """

  def recv(socket), do: recv(socket, "")

  # 250ms is experimental | connection latency into effect
  defp recv(socket, data), do: socket |> Core.recv(0, 250) |> recv(data, socket)
  defp recv({:ok, new}, data, socket), do: recv(socket, data <> new)
  defp recv({:error, :timeout}, data, _socket), do: data

  # If socket get's closed or unexpected error occurs
  defp recv({:error, :closed}, data, _s), do: data
  defp recv({:error, message}, _d, _s), do: raise(message)
end
