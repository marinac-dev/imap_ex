defmodule ImapEx.Imap.Command do
  @moduledoc """
  IMAP commands in form of an struct.\n
  I strongly suggest that user of this lib reads [RFC3501 Client Commands, Section 6](https://tools.ietf.org/html/rfc3501#section-6)\n
  [Formal syntax](https://tools.ietf.org/html/rfc3501#section-9)
  Submodules are strucutred in a way so that they "force" user to consciously select state
  """
  @type t :: %__MODULE__{
          tag: number(),
          command: struct(),
          imap_string: String.t()
        }
  defstruct tag: 0, command: nil, imap_string: ""

  @sp " "
  @eol "\r\n"
  @itag "I_TAG"

  @doc """
  Creates IMAP-ready command from Command sub-modules (Any, NonAuth, Auth, Selected)\n

  Usage:
      iex(∞)> command = Imap.Command.Any.noop()
      %Imap.Command.Any{command: "NOOP", params: [], type: :noop}
      iex(∞)> Imap.Command.forge(command)
      "I_TAG1 NOOP \\r\\n"
  """
  def forge(command, tag) do
    %__MODULE__{
      tag: tag(tag),
      command: command,
      imap_string: stringify(command, tag)
    }
  end

  defp stringify(%{command: command, params: params}, tag) when is_list(params) and is_integer(tag),
    do: tag(tag) <> @sp <> command <> @sp <> Enum.join(params, " ") <> @eol

  defp stringify(%{command: command, params: params}, tag) when is_bitstring(params) and is_integer(tag),
    do: tag(tag) <> @sp <> command <> @sp <> params <> @eol

  defp tag(tag), do: "#{@itag}#{tag}"

  defmodule Any do
    @moduledoc """
    Client Commands - Any State
    """
    defstruct command: nil, params: [], type: nil

    @doc """
    The [CAPABILITY](https://tools.ietf.org/html/rfc3501#section-6.1.1) command requests a listing of capabilities that the server supports.
    """
    def capability(), do: %__MODULE__{command: "CAPABILITY", type: :capability}

    @doc """
    The [NOOP](https://tools.ietf.org/html/rfc3501#section-6.1.2) command always succeeds. It does nothing.\n
    The NOOP command can also be used to reset any inactivity autologout timer on the server
    """
    def noop(), do: %__MODULE__{command: "NOOP", type: :noop}

    @doc """
    The [LOGOUT](https://tools.ietf.org/html/rfc3501#section-6.1.3) command informs the server that the client is done with the connection
    """
    def logout(), do: %__MODULE__{command: "LOGOUT", type: :logout}
  end

  defmodule NonAuth do
    @moduledoc """
    Client Commands - Not Authenticated State
    """
    defstruct command: nil, params: [], type: nil

    @doc """
    The [LOGIN](https://tools.ietf.org/html/rfc3501#section-6.2.3) command identifies the client to the server and carries \n
    the plaintext password authenticating this user
    """
    def login(acc, pass), do: %__MODULE__{command: "LOGIN", params: [acc, pass], type: :login}
  end

  defmodule Auth do
    @moduledoc """
    Client Commands - Authenticated State or Selected state
    """
    defstruct command: nil, params: [], type: nil

    @doc """
    The [SELECT](https://tools.ietf.org/html/rfc3501#section-6.3.1) command selects a mailbox so that messages in the
    mailbox can be accessed as read-write.
    """
    def select(mailbox_name),
      do: %__MODULE__{command: "SELECT", params: mailbox_name, type: :select}

    @doc """
    The [EXAMINE](https://tools.ietf.org/html/rfc3501#section-6.3.2) command is identical to SELECT and returns the same output \n
    however, the selected mailbox is identified as read-only.
    """
    def examine(mailbox_name),
      do: %__MODULE__{command: "EXAMINE", params: mailbox_name, type: :examine}

    @doc """
    The [CREATE](https://tools.ietf.org/html/rfc3501#section-6.3.3) command creates a mailbox with the given name
    """
    def create(folder_name),
      do: %__MODULE__{command: "CREATE", params: folder_name, type: :create}

    @doc """
    The [DELETE](https://tools.ietf.org/html/rfc3501#section-6.3.4) command permanently removes the mailbox with the given name
    """
    def delete(mailbox_name),
      do: %__MODULE__{command: "DELETE", params: mailbox_name, type: :delete}

    @doc """
    The [RENAME](https://tools.ietf.org/html/rfc3501#section-6.3.5) command changes the name of a mailbox.
    """
    def rename(existing_mailbox_name, new_mailbox_name),
      do: %__MODULE__{
        command: "RENAME",
        params: [existing_mailbox_name, new_mailbox_name],
        type: :rename
      }

    @doc """
    The [SUBSCRIBE](https://tools.ietf.org/html/rfc3501#section-6.3.6) command adds the specified mailbox name to the \n
    server's set of "active" or "subscribed" mailboxes as returned by the LSUB command
    """
    def subscribe(mailbox),
      do: %__MODULE__{command: "SUBSCRIBE", params: mailbox, type: :subscribe}

    @doc """
    The [UNSUBSCRIBE](https://tools.ietf.org/html/rfc3501#section-6.3.7) command removes the specified mailbox name from \n
    the server's set of "active" or "subscribed" mailboxes as returned by the LSUB command.
    """
    def unsubscribe(mailbox),
      do: %__MODULE__{command: "UNSUBSCRIBE", params: mailbox, type: :unsubscribe}

    @doc """
    The [LIST](https://tools.ietf.org/html/rfc3501#section-6.3.8) command returns a subset of names from the complete set of all names available to the client.
    """
    def list(reference_name, mailbox_name_or_wildcard),
      do: %__MODULE__{
        command: "LIST",
        params: [reference_name, mailbox_name_or_wildcard],
        type: :list
      }

    @doc """
    The [LSUB](https://tools.ietf.org/html/rfc3501#section-6.3.9) command returns a subset of names from the set of names \n
    that the user has declared as being "active" or "subscribed".
    """
    def lsub(reference_name, mailbox_name_or_wildcard),
      do: %__MODULE__{
        command: "LSUB",
        params: [reference_name, mailbox_name_or_wildcard],
        type: :lsub
      }

    @doc """
    The [STATUS](https://tools.ietf.org/html/rfc3501#section-6.3.10) command requests the status of the indicated mailbox.
    """
    def status(mailbox_name, status_att),
      do: %__MODULE__{command: "STATUS", params: [mailbox_name, status_att], type: :status}

    @doc """
    The [APPEND](https://tools.ietf.org/html/rfc3501#section-6.3.11) command appends the literal argument as a new message to the end of the specified destination mailbox.
    """
    def append(mailbox_name, flags \\ "", date_time \\ "", message_literal),
      do: %__MODULE__{
        command: "APPEND",
        params: [mailbox_name, flags, date_time, message_literal],
        type: :append
      }

    def idle(), do: %__MODULE__{command: "IDLE", type: :idle}

    def done(), do: %__MODULE__{command: "DONE", type: :done}
  end

  defmodule Selected do
    @moduledoc """
    Valid only when in Selected state
    """
    defstruct command: nil, params: [], type: nil

    @doc """
    The [CHECK](https://tools.ietf.org/html/rfc3501#section-6.4.1) command requests a checkpoint of the currently selected mailbox
    """
    def check(), do: %__MODULE__{command: "CHECK", type: :check}

    @doc """
    The [CLOSE](https://tools.ietf.org/html/rfc3501#section-6.4.2) command permanently removes all messages that have the\n
    `\\Deleted` flag set from the currently selected mailbox, and returns\n
    to the authenticated state from the selected state.
    """
    def close(), do: %__MODULE__{command: "CLOSE", type: :close}

    @doc """
    The [EXPUNGE](https://tools.ietf.org/html/rfc3501#section-6.4.3) command permanently removes all messages\n
    that have the `\\Deleted` flag set from the currently selected mailbox.
    """
    def expunge(), do: %__MODULE__{command: "EXPUNGE", type: :expunge}

    @doc """
    The [SEARCH](https://tools.ietf.org/html/rfc3501#section-6.4.4) command searches the mailbox for messages that match the given searching criteria.
    """
    def search(query), do: %__MODULE__{command: "SEARCH", params: query, type: :search}

    @doc """
    The [FETCH](https://tools.ietf.org/html/rfc3501#section-6.4.5) command retrieves data associated with a message in the mailbox.
    """
    def fetch(sequence, flags),
      do: %__MODULE__{command: "FETCH", params: [sequence, flags], type: :fetch}

    @doc """
    The [STORE](https://tools.ietf.org/html/rfc3501#section-6.4.6) command alters data associated with a message in the mailbox.
    """
    def store(sequence, md_item_name, v_md_item_name),
      do: %__MODULE__{
        command: "STORE",
        params: [sequence, md_item_name, v_md_item_name],
        type: :store
      }

    @doc """
    The [COPY](https://tools.ietf.org/html/rfc3501#section-6.4.7) command copies the specified message(s) to the end of the specified destination mailbox.
    """
    def copy(sequence, mailbox_name),
      do: %__MODULE__{command: "COPY", params: [sequence, mailbox_name], type: :copy}

    @doc """
    The [UID](https://tools.ietf.org/html/rfc3501#section-6.4.8) command has two forms.\n
    In the `first` form, it takes as its arguments a COPY, FETCH, or STORE command with arguments appropriate for the associated command.\n
    In the `second` form, the UID command takes a SEARCH command with SEARCH command arguments.
    """
    def uid(command, args), do: %__MODULE__{command: "UID", params: [command, args], type: :uid}

    @doc """
    The [UID MOVE](https://tools.ietf.org/html/rfc6851) command extends the first form of the UID command
    to add the MOVE command defined above as a valid argument.
    """
    def uid_move(sequence_set, mailbox_name),
      do: %__MODULE__{command: "UID MOVE", params: [sequence_set, mailbox_name], type: :uid_move}
  end
end
