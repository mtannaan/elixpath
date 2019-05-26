defmodule Elixpath do
  # import some example from README.md to run doctests
  readme = File.read!(__DIR__ |> Path.expand() |> Path.dirname() |> Path.join("README.md"))
  [examples] = Regex.run(~r/##\s*Examples.+/s, readme)

  @moduledoc """
             Extract data from possibly deeply-nested Elixir data structure using JSONPath-like path expressions.

             See [this page](readme.html) for syntax.
             """ <> examples

  require Elixpath.PathComponent, as: PathComponent
  require Elixpath.Tag, as: Tag

  @typedoc """
  String that represents an Elixpath.
  """
  @type path_string :: String.t()

  @typedoc """
  Elixpath, already compiled by `Elixpath.Parser.path/2` or `sigil_p/2`.
  """
  @type path :: [Elixpath.PathComponent.t()]

  @doc """
  Compiles string to internal Elixpath representation.

  Warning: Do not specify `unsafe_atom` modifier (`u`) for untrusted input.
  See `String.to_atom/1`, which this function uses to create new atom, for details.

  ## Modifiers

    * `unsafe_atom` (u) - passes `unsafe_atom: true` option to `Elixpath.Parser.path/2`.
    * `atom_keys_preferred` (a) - passes `prefer_keys: :atom` option to `Elixpath.Parser.path/2`.
  """
  defmacro sigil_p({:<<>>, _meta, [str]}, modifiers) do
    opts = [
      unsafe_atom: ?u in modifiers,
      prefer_keys: if(?a in modifiers, do: :atom, else: :string)
    ]

    path = Elixpath.Parser.path!(str, opts)

    quote do
      unquote(path)
    end
  end

  @doc """
  Query data from nested data structure.
  Returns list of matches, wrapped by `:ok`.
  When no match, `{:ok, []}` is returned.

  ## Options
    For path parsing options, see `Elixpath.Parser.path/2`.
  """
  @spec query(data :: term, path | path_string, [Elixpath.Parser.option()]) ::
          {:ok, [term]} | {:error, term}
  def query(data, path_or_str, opts \\ [])

  def query(data, str, opts) when is_binary(str) do
    with {:ok, compiled_path} <- Elixpath.Parser.path(str, opts) do
      query(data, compiled_path, opts)
    end
  end

  def query(data, path, opts) when is_list(path) do
    do_fetch(data, path, _gots = [], opts)
  end

  @spec do_fetch(term, path, list, Keyword.t()) :: {:ok, [term]} | {:error, term}
  defp do_fetch(_data, [], _gots, _opts), do: {:ok, []}

  defp do_fetch(data, [PathComponent.child(key)], _gots, opts) do
    Elixpath.Access.query(data, key, opts)
  end

  defp do_fetch(data, [PathComponent.child(key) | rest], _gots, opts) do
    with {:ok, children} <- Elixpath.Access.query(data, key, opts) do
      Enum.reduce_while(children, {:ok, []}, fn child, {:ok, gots_acc} ->
        case do_fetch(child, rest, gots_acc, opts) do
          {:ok, fetched} -> {:cont, {:ok, gots_acc ++ fetched}}
          error -> {:halt, error}
        end
      end)
    end
  end

  defp do_fetch(data, [PathComponent.descendant(key) | rest], gots, opts) do
    with direct_path <- [PathComponent.child(key) | rest],
         {:ok, direct_children} <- do_fetch(data, direct_path, gots, opts),
         indirect_path <- [
           PathComponent.child(Tag.wildcard()),
           PathComponent.descendant(key) | rest
         ],
         {:ok, indirect_children} <- do_fetch(data, indirect_path, gots, opts) do
      {:ok, direct_children ++ indirect_children}
    end
  end

  @doc """
  Query data from nested data structure.
  Same as `query/3`, except that `query!/3`raises on error.
  Returns `[]` when no match.
  """
  @spec query!(data :: term, path | path_string, [Elixpath.Parser.option()]) :: [term] | no_return

  def query!(data, path, opts \\ []) do
    case query(data, path, opts) do
      {:ok, got} -> got
      {:error, %_struct{} = error} -> raise error
      {:error, reason} -> raise "error occurred: #{inspect(reason)}"
    end
  end

  @doc """
  Get *single* data from nested data structure.
  Returns `default` when no match.
  Raises on error.
  """
  @spec get!(data :: term, path | path_string, default, [Elixpath.Parser.option()]) ::
          term | default | no_return
        when default: term
  def get!(data, path_or_str, default \\ nil, opts \\ [])

  def get!(data, str, default, opts) when is_binary(str) do
    case Elixpath.Parser.path(str, opts) do
      {:ok, compiled_path} -> get!(data, compiled_path, default, opts)
      {:error, reason} -> raise "error parsing path: #{inspect(reason)}"
    end
  end

  def get!(data, path, default, opts) when is_list(path) do
    case query!(data, path, opts) do
      [] -> default
      [head | _rest] -> head
    end
  end
end
