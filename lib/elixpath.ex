defmodule Elixpath do
  # Import some example from README.md to run doctests.
  # Make sure to touch (i.e. update timestamp of) this file
  # when editing examples in README.md.
  readme = File.read!(__DIR__ |> Path.expand() |> Path.dirname() |> Path.join("README.md"))
  [examples] = Regex.run(~r/##\s*Examples.+/s, readme)

  @moduledoc """
             Extract data from possibly deeply-nested Elixir data structure using JSONPath-like path expressions.

             See [this page](readme.html) for syntax.
             """ <> examples

  require Elixpath.PathComponent, as: PathComponent
  require Elixpath.Tag, as: Tag

  @typedoc """
  Elixpath, already compiled by `Elixpath.Parser.parse/2` or `sigil_p/2`.
  """
  @type t :: %__MODULE__{path: [PathComponent.t()]}
  defstruct path: []

  @doc """
  Compiles string to internal Elixpath representation.

  Warning: Do not specify `unsafe_atom` modifier (`u`) for untrusted input.
  See `String.to_atom/1`, which this function uses to create new atom, for details.

  ## Modifiers

  * `unsafe_atom` (u) - passes `unsafe_atom: true` option to `Elixpath.Parser.parse/2`.
  * `atom_keys_preferred` (a) - passes `prefer_keys: :atom` option to `Elixpath.Parser.parse/2`.

  ## Examples

  ```elixir
  iex> import Elixpath, only: [sigil_p: 2]
  iex> ~p/.string..:b[1]/
  #Elixpath<[elixpath_child: "string", elixpath_descendant: :b, elixpath_child: 1]>
  iex> ~p/.atom..:b[1]/a
  #Elixpath<[elixpath_child: :atom, elixpath_descendant: :b, elixpath_child: 1]>
  ```
  """
  defmacro sigil_p({:<<>>, _meta, [str]}, modifiers) do
    opts = [
      unsafe_atom: ?u in modifiers,
      prefer_keys: if(?a in modifiers, do: :atom, else: :string)
    ]

    path = Elixpath.Parser.parse!(str, opts) |> Macro.escape()

    quote do
      unquote(path)
    end
  end

  @doc """
  Query data from nested data structure.
  Returns list of matches, wrapped by `:ok`.
  When no match, `{:ok, []}` is returned.

  ## Options
    For path parsing options, see `Elixpath.Parser.parse/2`.
  """
  @spec query(data :: term, t | String.t(), [Elixpath.Parser.option()]) ::
          {:ok, [term]} | {:error, reason :: term}
  def query(data, path_or_str, opts \\ [])

  def query(data, str, opts) when is_binary(str) do
    with {:ok, compiled_path} <- Elixpath.Parser.parse(str, opts) do
      query(data, compiled_path, opts)
    end
  end

  def query(data, %Elixpath{} = path, opts) do
    do_query(data, path, _gots = [], opts)
  end

  @spec do_query(term, t, list, Keyword.t()) :: {:ok, [term]} | {:error, reason :: term}
  defp do_query(_data, %Elixpath{path: []}, _gots, _opts), do: {:ok, []}

  defp do_query(data, %Elixpath{path: [PathComponent.child(key)]}, _gots, opts) do
    Elixpath.Access.query(data, key, opts)
  end

  defp do_query(data, %Elixpath{path: [PathComponent.child(key) | rest]} = path, _gots, opts) do
    with {:ok, children} <- Elixpath.Access.query(data, key, opts) do
      Enum.reduce_while(children, {:ok, []}, fn child, {:ok, gots_acc} ->
        case do_query(child, %{path | path: rest}, gots_acc, opts) do
          {:ok, fetched} -> {:cont, {:ok, gots_acc ++ fetched}}
          error -> {:halt, error}
        end
      end)
    end
  end

  defp do_query(data, %Elixpath{path: [PathComponent.descendant(key) | rest]} = path, gots, opts) do
    with direct_path <- %{path | path: [PathComponent.child(key) | rest]},
         {:ok, direct_children} <- do_query(data, direct_path, gots, opts),
         indirect_path <- %{
           path
           | path: [
               PathComponent.child(Tag.wildcard()),
               PathComponent.descendant(key) | rest
             ]
         },
         {:ok, indirect_children} <- do_query(data, indirect_path, gots, opts) do
      {:ok, direct_children ++ indirect_children}
    end
  end

  @doc """
  Query data from nested data structure.
  Same as `query/3`, except that `query!/3`raises on error.
  Returns `[]` when no match.
  """
  @spec query!(data :: term, t | String.t(), [Elixpath.Parser.option()]) :: [term] | no_return

  def query!(data, path, opts \\ []) do
    case query(data, Elixpath.Parser.parse!(path, opts), opts) do
      {:ok, got} -> got
    end
  end

  @doc """
  Get *single* data from nested data structure.
  Returns `default` when no match.
  Raises on error.
  """
  @spec get!(data :: term, t | String.t(), default, [Elixpath.Parser.option()]) ::
          term | default | no_return
        when default: term
  def get!(data, path_or_str, default \\ nil, opts \\ [])

  def get!(data, str, default, opts) when is_binary(str) do
    get!(data, Elixpath.Parser.parse!(str, opts), default, opts)
  end

  def get!(data, %Elixpath{} = path, default, opts) do
    case query!(data, path, opts) do
      [] -> default
      [head | _rest] -> head
    end
  end

  @doc ~S"""
  Converts Elixpath to string.
  Also available via `Kernel.to_string/1`.

  This function is named `stringify/1` to avoid name collision
  with `Kernel.to_string/1` when the entire module is imported.

  ## Examples

    iex> import Elixpath, only: [sigil_p: 2]
    iex> path = ~p/.1.child..:decendant/u
    #Elixpath<[elixpath_child: 1, elixpath_child: "child", elixpath_descendant: :decendant]>
    iex> path |> to_string()
    "[1].\"child\"..:decendant"
    iex> "interpolation: #{~p/..1[*]..*/}"
    "interpolation: ..[1].*..*"
  """
  @spec stringify(t) :: String.t()
  def stringify(path) do
    Enum.map_join(path.path, fn
      PathComponent.child(Tag.wildcard()) -> ".*"
      PathComponent.descendant(Tag.wildcard()) -> "..*"
      PathComponent.child(int) when is_integer(int) -> "[#{inspect(int)}]"
      PathComponent.descendant(int) when is_integer(int) -> "..[#{inspect(int)}]"
      PathComponent.child(x) -> ".#{inspect(x)}"
      PathComponent.descendant(x) -> "..#{inspect(x)}"
    end)
  end
end

defimpl Inspect, for: Elixpath do
  @spec inspect(Elixpath.t(), Inspect.Opts.t()) :: Inspect.Algebra.t()
  def inspect(path, opts) do
    Inspect.Algebra.concat(["#Elixpath<", Inspect.Algebra.to_doc(path.path, opts), ">"])
  end
end

defimpl String.Chars, for: Elixpath do
  @spec to_string(Elixpath.t()) :: binary
  def to_string(path), do: Elixpath.stringify(path)
end

defimpl List.Chars, for: Elixpath do
  @spec to_charlist(Elixpath.t()) :: charlist
  def to_charlist(path), do: Elixpath.stringify(path) |> String.to_charlist()
end
