defmodule Elixpath.Parser do
  @moduledoc """
  Parses Elixpath expressions.
  """
  import NimbleParsec

  @type option :: {:unsafe_atom, boolean} | {:prefer_keys, :string | :atom}

  defmodule ParseError do
    @moduledoc """
    Syntax error while parsing Elixpath string.
    """
    defexception [:message]
  end

  defparsecp(:parse_path, __MODULE__.Grammar.path())

  @doc """
  Parses an Elixpath expression.
  See [this page](readme.html) for syntax.

  Warning: when `unsafe_atom: true` is specified, this function creates new atom using `String.to_atom/1`.
  Do not specify `unsafe_atom: true` for untrusted input.
  See `String.to_atom/1` for details.

  ## Options

    - `:unsafe_atom` - if `true`, allows to create non-existing atoms, defaults to `false`.
    - `:prefer_keys` - unquoted keys are converted to string (`:string`) or atom (`:atom`). Defaults to `:string`.
  """
  @spec parse(String.t() | Elixpath.t(), [option]) ::
          {:ok, Elixpath.t()} | {:error, reason :: term}
  def parse(str_or_path, opts \\ [])

  def parse(%Elixpath{} = path, _opts) do
    {:ok, path}
  end

  def parse(str, opts) when is_binary(str) do
    case parse_path(str, context: %{opts: opts}) do
      {:ok, result, "", _context, _line, _column} ->
        {:ok, %Elixpath{path: result}}

      {:ok, result, rest, _context, _line, _column} ->
        # we mustn't be here because Grammer.path ends with eos()
        {:error, "did not reach the end of string. result: #{inspect(result)}, rest: #{rest}"}

      {:error, reason, _rest, _context, _line, _column} ->
        {:error, reason}
    end
  end

  def parse(other, _opts) do
    {:error, "unexpected input type: #{inspect(other)}"}
  end

  @doc """
  Parses an Elixpath expression.
  Raises on error.
  See `parse/2` for available options.
  """
  @spec parse!(String.t() | Elixpath.t(), [option]) :: Elixpath.t() | no_return
  def parse!(str_or_path, opts \\ []) do
    case parse(str_or_path, opts) do
      {:ok, result} ->
        result

      {:error, reason} when is_binary(reason) ->
        raise ParseError, message: "error parsing path #{inspect(str_or_path)}: #{reason}"
    end
  end
end
