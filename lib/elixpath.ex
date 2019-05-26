defmodule Elixpath do
  @moduledoc """
  Documentation for Elixpath.
  """

  require Elixpath.Node, as: Node
  require Elixpath.Tag, as: Tag

  # inspect variable for debugging
  defmacrop iv({name, _meta, nil} = var) do
    quote do
      IO.inspect(unquote(var), label: unquote(to_string(name)))
    end
  end

  @doc """
  Get item from nested data structure.

  ## Examples



  """
  def query(data, path_or_str, opts \\ [])

  def query(data, str, opts) when is_binary(str) do
    with {:ok, compiled_path} <- Elixpath.Parser.path(str, opts) do
      query(data, compiled_path, opts)
    end
  end

  def query(data, path, opts) when is_list(path) do
    do_fetch(data, path, _gots = [], opts)
  end

  defp do_fetch(_data, [], _gots, _opts), do: {:ok, []}

  defp do_fetch(data, [Node.child(key)], _gots, opts) do
    Elixpath.Access.query(data, key, opts)
  end

  defp do_fetch(data, [Node.child(key) | rest], _gots, opts) do
    with {:ok, children} <- Elixpath.Access.query(data, key, opts) do
      Enum.reduce_while(children, {:ok, []}, fn child, {:ok, gots_acc} ->
        case do_fetch(child, rest, gots_acc, opts) do
          {:ok, fetched} -> {:cont, {:ok, gots_acc ++ fetched}}
          error -> {:halt, error}
        end
      end)
    end
  end

  defp do_fetch(data, [Node.descendant(key) | rest], gots, opts) do
    with direct_path <- [Node.child(key) | rest],
         {:ok, direct_children} <- do_fetch(data, direct_path, gots, opts),
         indirect_path <- [Node.child(Tag.wildcard()), Node.descendant(key) | rest],
         {:ok, indirect_children} <- do_fetch(data, indirect_path, gots, opts) do
      {:ok, direct_children ++ indirect_children}
    end
  end

  def query!(data, path, opts \\ []) do
    case query(data, path, opts) do
      {:ok, got} -> got
      {:error, %_struct{} = error} -> raise error
      {:error, reason} -> raise "error occurred: #{inspect(reason)}"
    end
  end

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
