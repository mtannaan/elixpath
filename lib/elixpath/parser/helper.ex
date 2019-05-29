defmodule Elixpath.Parser.Helper do
  @moduledoc false

  def post_traverse_string_or_atom(_rest, [result], context, _line, _offset, additional_opts) do
    opts = additional_opts ++ Map.get(context, :opts, [])
    prefer_keys = Keyword.get(opts, :prefer_keys, :string)

    case prefer_keys do
      :string ->
        {[result], context}

      :atom ->
        with {:ok, atom} <- to_atom(result, opts) do
          {[atom], context}
        end
    end
  end

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

  @spec to_atom(String.t(), list) :: {:ok, atom} | {:error, reason :: term}
  def to_atom(string, _opts) when is_binary(string) and byte_size(string) > 255 do
    {:error, "atom length must be less than system limit: #{string}"}
  end

  def to_atom(string, opts) do
    unless Keyword.get(opts, :unsafe_atom, false) do
      try do
        {:ok, String.to_existing_atom(string)}
      rescue
        ArgumentError ->
          {:error, ~s/:"#{string}" does not exist while :unsafe_atom is not given./}
      end
    else
      {:ok, String.to_atom(string)}
    end
  end

  def map_escaped(~S/"/), do: ~S/"/
  def map_escaped(~S/'/), do: ~S/'/
  def map_escaped("b"), do: "\b"
  def map_escaped("e"), do: "\e"
  def map_escaped("f"), do: "\f"
  def map_escaped("n"), do: "\n"
  def map_escaped("r"), do: "\r"
  def map_escaped("s"), do: "\s"
  def map_escaped("t"), do: "\t"
  def map_escaped("v"), do: "\v"
  def map_escaped(other), do: other

  def map_integer([int]), do: int
  def map_integer(["-", int]), do: -1 * int
end
