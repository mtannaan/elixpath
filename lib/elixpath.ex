defmodule Elixpath do
  @moduledoc """
  Documentation for Elixpath.
  """

  @doc """
  Get item from nested data structure.

  ## Examples



  """
  def fetch(data, path, opts \\ []) do
    with {:ok, compiled_path} <- Elixpath.Parser.path(path, opts) do
      do_fetch(data, compiled_path, _gots = [], opts)
    end
  end

  defp do_fetch(data, [last], _gots, opts) do
    Elixpath.Access.get(data, last, opts)
  end

  defp do_fetch(data, [head | rest], gots, opts) do
    with {:ok, child} <- Elixpath.Access.get(data, head, opts) do
      do_fetch(child, rest, gots, opts)
    end
  end

  def fetch!(data, path, opts \\ []) do
    case fetch(data, path, opts) do
      {:ok, got} -> got
      {:error, error} -> raise error
    end
  end

  def get(data, path, default \\ nil, opts \\ []) do
    case fetch(data, path, opts) do
      {:ok, got} -> got
      {:error, _reason} -> default
    end
  end
end
