# ImapEx - Elixir IMAP client library

## About [WIP]

Imap client library written in Elixir, with goal to be secure, fast and asyn.

## Roadmap:

- [x] SSL base | Support only secure IMAP on port 993
- [ ] IMAP Commands
- [ ] IMAP response parser
- [ ] IMAP connectio manager (GenServer)
- [ ] High level API Client | User friendly

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `imap_ex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:imap_ex, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/imap_ex](https://hexdocs.pm/imap_ex).
