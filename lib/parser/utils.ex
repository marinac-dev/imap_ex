defmodule ImapEx.Parser.Utils do
  # Thank you sgessa/eximap <3

  def parse_number(rest) do
    [val, sep, rest] = String.split(rest, ~r{\d+(?<non_digit>[^\d])}, on: [:non_digit], parts: 2, include_captures: true)

    {val, sep <> rest}
  end

  def parse_nz_number(rest) do
    case String.split(rest, ~r{[1-9]\d*(?<space>\s)}, on: [:space], parts: 2) do
      [val, rest] -> {val, rest}
      [val] -> {val, ""}
    end
  end

  def parse_nstring("NIL" <> data), do: {"NIL", data}
  def parse_nstring(" " <> data), do: parse_string(data)
  def parse_nstring(data), do: parse_string(data)

  def parse_string("\"" <> _ = data), do: parse_quoted(data)
  def parse_string("{" <> _ = data), do: parse_literal(data)
  def parse_string(data), do: IO.warn("String parser failed at: #{inspect(data)}")

  def parse_literal(data) do
    "{" <> rest = data
    [len, rest] = String.split(rest, "}\r\n", parts: 2)
    len = len |> String.to_integer()
    split_bytes(rest, len)
  end

  def parse_quoted(rest) do
    "\"" <> rest = rest

    split_location =
      rest
      |> :binary.bin_to_list()
      |> Enum.reduce_while(%{idx: 0, escape_seq: false}, fn ch, %{idx: idx, escape_seq: escape_seq} ->
        cond do
          ch == ?" && escape_seq == false ->
            {:halt, %{idx: idx, escape_seq: false}}

          ch == ?\  && escape_seq == false ->
            {:cont, %{idx: idx + 1, escape_seq: true}}

          true ->
            {:cont, %{idx: idx + 1, escape_seq: false}}
        end
      end)
      |> Map.fetch!(:idx)

    split_bytes(rest, split_location, true)
  end

  def split_bytes(bin, loc, split_loc \\ false) do
    {l, r} = bin |> :binary.bin_to_list() |> Enum.split(loc)
    r = if split_loc, do: Enum.drop(r, 1), else: r
    {:binary.list_to_bin(l), :binary.list_to_bin(r)}
  end
end
