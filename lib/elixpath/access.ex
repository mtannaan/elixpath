defprotocol Elixpath.Access do
  @fallback_to_any true

  def fetch_all(data, key, opts)
end

defimpl Elixpath.Access, for: Any do
  def fetch_all(_data, _key, _opts), do: {:ok, []}
end

defimpl Elixpath.Access, for: Map do
  require Elixpath.Tag

  def fetch_all(data, Elixpath.Tag.wildcard(), _opts) do
    {:ok, Map.values(data)}
  end

  def fetch_all(data, key, _opts) do
    case Map.fetch(data, key) do
      {:ok, fetched} -> {:ok, [fetched]}
      :error -> {:ok, []}
    end
  end
end
