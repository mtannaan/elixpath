defprotocol Elixpath.Access do
  @moduledoc """
  Used for querying each data type.
  """

  @fallback_to_any true

  @doc """
  Fetches all children that matches `key` from `data`.
  `key` can be `Elixpath.Tag.wildcard()`, which stands for "all the children"
  """
  @spec query(data :: term, key :: term, opts :: list) :: {:ok, [term]} | {:error, reason :: term}
  def query(data, key, opts)
end

defimpl Elixpath.Access, for: Any do
  def query(_data, _key, _opts), do: {:ok, []}
end

defimpl Elixpath.Access, for: Map do
  require Elixpath.Tag

  def query(data, Elixpath.Tag.wildcard(), _opts) do
    {:ok, Map.values(data)}
  end

  def query(data, key, _opts) do
    case Map.fetch(data, key) do
      {:ok, fetched} -> {:ok, [fetched]}
      :error -> {:ok, []}
    end
  end
end

defimpl Elixpath.Access, for: List do
  require Elixpath.Tag

  def query(data, Elixpath.Tag.wildcard(), _opts) do
    if Keyword.keyword?(data) do
      {:ok, Keyword.values(data)}
    else
      {:ok, data}
    end
  end

  def query(data, index, opts) when is_integer(index) and index < 0 do
    Elixpath.Access.query(data, length(data) + index, opts)
  end

  def query(data, index, _opts) when is_integer(index) and index >= 0 do
    case Enum.at(data, index, _default = :elixpath_not_found) do
      :elixpath_not_found -> {:ok, []}
      got -> {:ok, [got]}
    end
  end

  def query(data, key, _opts) do
    values =
      data
      |> Enum.filter(fn
        {^key, _value} -> true
        _otherwise -> false
      end)
      |> Enum.map(fn {_key, value} -> value end)

    {:ok, values}
  end
end
