defmodule Elixpath.Parser.Helper do
  @moduledoc false
  # NimbleParsec changed after 1.2.1 to require 3 tuple instead of 2 tuple.
  @nimble_parsec_version Application.spec(:nimble_parsec, :vsn)
                         |> to_string()
                         |> String.split(".")
                         |> Enum.map(&String.to_integer/1)
                         |> (fn [major, minor, patch] ->
                               (major == 1 and minor > 2) or
                                 (major == 1 and minor == 2 and patch >= 2)
                             end).()

  def post_traverse_string_or_atom(rest, [result], context, _line, _offset, additional_opts) do
    opts = additional_opts ++ Map.get(context, :opts, [])
    prefer_keys = Keyword.get(opts, :prefer_keys, :string)

    case prefer_keys do
      :string ->
        if @nimble_parsec_version do
          {rest, [result], context}
        else
          {[result], context}
        end

      :atom ->
        with {:ok, atom} <- to_atom(result, opts) do
          if @nimble_parsec_version do
            {rest, [atom], context}
          else
            {[atom], context}
          end
        end
    end
  end

  def post_traverse_atom(rest, results, context, _line, _offset, additional_opts) do
    opts = additional_opts ++ Map.get(context, :opts, [])

    %{ok: new_results, error: errors} =
      Enum.map(results, fn result -> to_atom(result, opts) end)
      |> Enum.group_by(_key_fun = &elem(&1, 0), _value_fun = &elem(&1, 1))
      |> Enum.into(%{ok: [], error: []})

    unless Enum.empty?(errors) do
      {:error, List.first(errors)}
    else
      if @nimble_parsec_version do
        {rest, new_results, context}
      else
        {new_results, context}
      end
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
