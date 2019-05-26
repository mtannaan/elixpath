defmodule Elixpath.Parser.Atom do
  def post_traverse_atom(_rest, results, context, _line, _offset, additional_opts) do
    opts = additional_opts ++ Map.get(context, :opts, [])

    %{ok: new_results, error: errors} =
      Enum.map(results, fn result -> to_atom(result, opts) end)
      |> Enum.group_by(_key_fun = &elem(&1, 0), _value_fun = &elem(&1, 1))
      |> Enum.into(%{ok: [], error: []})

    unless Enum.empty?(errors) do
      {:error, List.first(errors)}
    else
      {new_results, context}
    end
  end

  def to_atom(string, _opts) when is_binary(string) and byte_size(string) > 255 do
    {:error, "atom length must be less than system limit: #{string}"}
  end

  def to_atom(string, opts) do
    unless Keyword.get(opts, :create_non_existing_atom, false) do
      try do
        {:ok, String.to_existing_atom(string)}
      rescue
        ArgumentError ->
          {:error, ~s/:"#{string}" does not exist while :create_non_existing_atom is not given./}
      end
    else
      {:ok, String.to_atom(string)}
    end
  end
end
