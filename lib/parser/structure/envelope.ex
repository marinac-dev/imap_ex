defmodule ImapEx.Parser.Structure.Envelope do
  @type t :: %__MODULE__{
          date: String.t(),
          subject: String.t(),
          from: list(),
          sender: list(),
          reply_to: list(),
          to: list(),
          cc: list(),
          bcc: list(),
          in_reply_to: String.t(),
          message_id: String.t()
        }

  defstruct [:date, :subject, :from, :sender, :reply_to, :to, :cc, :bcc, :in_reply_to, :message_id]
  alias ImapEx.Parser.Utils

  def parse("(" <> data), do: parse(data |> reverse())

  def parse(env) do
    {reverse(env), %__MODULE__{}}
    |> parse_nstring(:date)
    |> parse_nstring(:subject)
    |> parse_naddress_list(:from)
    |> parse_naddress_list(:sender)
    |> parse_naddress_list(:reply_to)
    |> parse_naddress_list(:to)
    |> parse_naddress_list(:cc)
    |> parse_naddress_list(:bcc)
    |> parse_nstring(:in_reply_to)
    |> parse_nstring(:message_id)
    |> then(fn {_, env} -> env end)
  end

  defp parse_nstring({data, res}, key), do: data |> Utils.parse_nstring() |> parse_nstring(res, key)
  defp parse_nstring({value, " " <> rest}, res, key), do: {rest, %{res | key => value}}
  defp parse_nstring({value, rest}, res, key), do: {rest, %{res | key => value}}

  defp parse_naddress_list({data, res}, key), do: data |> parse_naddress_list() |> parse_naddress_list(res, key)
  defp parse_naddress_list({value, " " <> rest}, res, key), do: {rest, %{res | key => value}}
  defp parse_naddress_list({value, rest}, res, key), do: {rest, %{res | key => value}}

  defp parse_naddress_list("NIL" <> rest), do: {"NIL", rest}
  defp parse_naddress_list("(" <> rest), do: parse_address_list(rest, [])

  defp parse_address_list(")" <> rest, acc), do: {acc, rest}

  defp parse_address_list("(" <> rest, acc) do
    {name, rest} = Utils.parse_nstring(rest)
    {adl, rest} = Utils.parse_nstring(rest)
    {mailbox, rest} = Utils.parse_nstring(rest)
    {host, rest} = Utils.parse_nstring(rest)

    ")" <> rest = rest
    addr = %{name: name, adl: adl, mailbox: mailbox, host: host}
    parse_address_list(rest, acc ++ [addr])
  end

  defp reverse(data), do: data |> :binary.decode_unsigned(:little) |> :binary.encode_unsigned(:big)
end
