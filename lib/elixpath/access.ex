defprotocol Elixpath.Access do
  def get(data, path_comp, opts)
end

defimpl Elixpath.Access, for: Map do
  require Elixpath.Node

  def get(data, Elixpath.Node.child(key), _opts) do
    case Map.fetch(data, key) do
      {:ok, _} = ok -> ok
      :error -> {:error, %KeyError{term: data, key: {:child, key}}}
    end
  end
end
