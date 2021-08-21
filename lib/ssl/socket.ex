defmodule ImapEx.SSL.Socket do
  alias ImapEx.SSL.Core

  def init(host, port) when is_bitstring(host) and is_integer(port) do
    # We want SSL to either start or break
    :ok = Core.start()

    host
    |> to_charlist()
    |> Core.connect(port)
    |> handle_init()
  end

  defp handle_init({:error, reason}), do: {:error, reason}

  defp handle_init({:ok, socket}) do
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
  Used when IMAP initializes connection with server (response up to 64kb)
  """
  def init_recv(socket) when is_tuple(socket), do: Core.recv(socket, 0)

  @doc """
  Recieve data from socket until the end of IMAP response is reached.
  """

  def recv(socket), do: recv(socket, "")

  defp recv(socket, data),
    do: socket |> Core.recv() |> recv(socket, data)

  defp recv({:ok, new}, socket, data),
    do: new |> reverse() |> recv(socket, data)

  defp recv({:error, reason}, _s, _d), do: IO.warn(reason)

  defp recv("\n\r." <> reversed = _new, _socket, data),
    do: data <> reverse(reversed)

  defp recv(new, socket, data), do: recv(socket, data <> reverse(new))

  defp reverse(data),
    do: data |> :binary.decode_unsigned(:little) |> :binary.encode_unsigned(:big)
end
