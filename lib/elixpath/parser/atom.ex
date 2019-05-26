defmodule Elixpath.Parser.Atom do
  def to_atom(string, _opts) when is_binary(string) and byte_size(string) > 255 do
    {:error, "atom length must be less than system limit: #{string}"}
  end

  def to_atom(string, opts) do
    with :ok <- check_nfc(string, opts) do
      if opts[:existing_atoms_only] do
        try do
          {:ok, String.to_existing_atom(string)}
        rescue
          ArgumentError ->
            {:error, ~s/:"#{string}" does not exist while :existing_atoms_only is specified./}
        end
      else
        {:ok, String.to_atom(string)}
      end
    end
  end

  defp check_nfc(string, opts) do
    if not opts[:quoted] or to_charlist(string) === :unicode.characters_to_nfc_list(string) do
      :ok
    else
      {:error, ~s/non-NFC form while :quoted option not passed: #{string}/}
    end
  end

  # Letter handling is based on:
  # elixir/lib/elixir/unicode/tokenizer.ex
  data_path = Path.join(__DIR__, "UnicodeData")

  {letter_uptitlecase, start, continue, _} =
    Enum.reduce(File.stream!(data_path), {[], [], [], nil}, fn line, acc ->
      {letter_uptitlecase, start, continue, first} = acc
      [codepoint, line] = :binary.split(line, ";")
      [name, line] = :binary.split(line, ";")
      [category, _] = :binary.split(line, ";")

      {codepoints, first} =
        case name do
          "<" <> _ when is_integer(first) ->
            last = String.to_integer(codepoint, 16)
            {Enum.to_list(last..first), nil}

          "<" <> _ ->
            first = String.to_integer(codepoint, 16)
            {[first], first + 1}

          _ ->
            {[String.to_integer(codepoint, 16)], nil}
        end

      cond do
        category in ~w(Lu Lt) ->
          {codepoints ++ letter_uptitlecase, start, continue, first}

        category in ~w(Ll Lm Lo Nl) ->
          {letter_uptitlecase, codepoints ++ start, continue, first}

        category in ~w(Mn Mc Nd Pc) ->
          {letter_uptitlecase, start, codepoints ++ continue, first}

        true ->
          {letter_uptitlecase, start, continue, first}
      end
    end)

  prop_path = Path.join(__DIR__, "PropList")

  {start, continue, patterns} =
    Enum.reduce(File.stream!(prop_path), {start, continue, []}, fn line, acc ->
      [codepoints | category] = :binary.split(line, ";")

      pos =
        case category do
          [" Other_ID_Start" <> _] -> 0
          [" Other_ID_Continue" <> _] -> 1
          [" Pattern_White_Space" <> _] -> 2
          [" Pattern_Syntax" <> _] -> 2
          _ -> -1
        end

      if pos >= 0 do
        entries =
          case :binary.split(codepoints, "..") do
            [<<codepoint::4-binary, _::binary>>] ->
              [String.to_integer(codepoint, 16)]

            [first, <<last::4-binary, _::binary>>] ->
              Enum.to_list(String.to_integer(last, 16)..String.to_integer(first, 16))
          end

        put_elem(acc, pos, entries ++ elem(acc, pos))
      else
        acc
      end
    end)

  id_upper = letter_uptitlecase -- patterns
  id_start = start -- patterns
  id_continue = continue -- patterns

  unicode_upper = Enum.filter(id_upper, &(&1 > 127))
  unicode_start = Enum.filter(id_start, &(&1 > 127))
  unicode_continue = Enum.filter(id_continue, &(&1 > 127))

  rangify = fn [head | tail] ->
    {first, last, acc} =
      Enum.reduce(tail, {head, head, []}, fn
        number, {first, last, acc} when number == first - 1 ->
          {number, last, acc}

        number, {first, last, acc} ->
          {number, number, [{first, last} | acc]}
      end)

    [{first, last} | acc]
  end

  to_range = fn {first, last} -> quote(do: unquote(first)..unquote(last)) end

  # types are to fit [NimbleParsec.range()]
  ranges_ascii_upper = [to_range.({?A, ?Z})]
  ranges_ascii_start = [?_, to_range.({?a, ?z})]
  ranges_ascii_continue = [to_range.({?0, ?9})]

  ranges_unicode_upper =
    rangify.(unicode_upper)
    |> Enum.into([{:not, ?_}], to_range)

  ranges_unicode_start =
    rangify.(unicode_start)
    |> Enum.into([{:not, ?_}], to_range)

  unless to_range.({13312, 19893}) in ranges_unicode_start do
    raise "CHECK: CJK Ideograph not in range"
  end

  ranges_unicode_continue =
    rangify.(unicode_continue)
    |> Enum.into([{:not, ?_}], to_range)

  ranges_atom_start =
    Enum.concat([
      ranges_ascii_upper,
      ranges_ascii_start,
      ranges_unicode_upper,
      ranges_unicode_start
    ])

  ranges_atom_continue =
    Enum.concat([
      ranges_ascii_start,
      ranges_ascii_upper,
      ranges_ascii_continue,
      [?@],
      ranges_unicode_start,
      ranges_unicode_upper,
      ranges_unicode_continue
    ])

  ranges_atom_end =
    Enum.concat([
      ranges_ascii_start,
      ranges_ascii_upper,
      ranges_ascii_continue,
      [?@, ??, ?!],
      ranges_unicode_start,
      ranges_unicode_upper,
      ranges_unicode_continue
    ])

  import NimbleParsec

  def non_quoted_atom do
    utf8_string(unquote(ranges_atom_start), 1)
    |> optional(utf8_string(unquote(ranges_atom_continue), min: 1))
    |> optional(utf8_string(unquote(ranges_atom_end), 1))
    |> reduce({Enum, :join, []})
  end
end
