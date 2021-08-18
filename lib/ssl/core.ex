defmodule ImapEx.SSL.Core do
  @moduledoc """
  Core of library is connection tools to interact with server.
  """

  @opts [:binary, active: false]

  @doc """
  Starts SSL aplication and opens port.
  """
  def start(), do: :ssl.start()

  @doc """
  Connects to host:port.
  Default opts `[mode: :binary, active: false]`
  """
  def connect(host, port, opts \\ @opts) when is_integer(port) and is_list(opts),
    do: :ssl.connect(host, port, opts)

  @doc """
  Sends data through socket.
  """
  def send(socket, data) when is_tuple(socket) and is_bitstring(data),
    do: :ssl.send(socket, data)

  @doc """
  Recieves data of lenght(size) `len` from socket.
  Default len is 0 = `as much as possible`.
  Size is in bytes.
  """
  def recv(socket, len \\ 0) when is_tuple(socket) and is_integer(len),
    do: :ssl.recv(socket, len)

  @doc """
  Closes CONNECTION of socket but SSL is still alive.
  To stop SSL app and close ports openned by it use stop.
  """
  def close(socket) when is_tuple(socket),
    do: :ssl.close(socket)

  @doc """
  Stops SSL app and closes ports.
  """
  def stop, do: :ssl.stop()
end
