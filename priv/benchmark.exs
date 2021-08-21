defmodule Test do
  @byte_size 65536

  def load_file(), do: File.stream!("priv/emails/email_source.txt", [], @byte_size) |> Enum.map(& &1)

  def recv_regex(), do: load_file() |> recv_regex("")
  def recv_regex([new | rest], data),
    do: if Regex.match?(~r/.*\r\n$/s, new), do: data <> new, else: recv_regex(rest, data <> new)

  def recv_match(), do: load_file() |> recv_match("")
  def recv_match([new | rest], data), do: new |> reverse() |> handle_recv(rest, data)

  defp handle_recv("\n\r" <> reversed = _new, _rest, data), do: data <> reverse(reversed)
  defp handle_recv(new, rest, data),do: recv_match(rest, data <> new)

  defp reverse(data), do: data |> :binary.decode_unsigned(:little) |> :binary.encode_unsigned(:big)
end


Benchee.run(%{
  "recv_regex" => fn -> Test.recv_regex() end,
  "recv_match" => fn -> Test.recv_match() end
}, time: 5)
