defmodule Elixpath.Parser do
  import NimbleParsec

  defmodule ParseError do
    defexception [:message]
  end

  defparsecp(:parse_path, __MODULE__.Components.path())

  @doc """
  ## Options

    - :unsafe_atom - if `true`, allows to create non-existing atoms, defaults to false
  """
  def path(str, opts \\ []) do
    case parse_path(str, context: %{opts: opts}) do
      {:ok, result, "", _context, _line, _column} ->
        {:ok, result}

      {:ok, result, rest, _context, _line, _column} ->
        {:error, "did not reach the end of string. result: #{inspect(result)}, rest: #{rest}"}

      {:error, reason, _rest, _context, _line, _column} ->
        {:error, reason}
    end
  end

  def path!(str, opts \\ []) do
    case path(str, opts) do
      {:ok, result} -> result
      {:error, reason} -> raise Elixpath.Parser.ParseError, message: reason
    end
  end
end
