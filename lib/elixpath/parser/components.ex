defmodule Elixpath.Parser.Components do
  import NimbleParsec
  require Elixpath.Tag, as: Tag

  # suppress seemingly false-positive warnings
  # maybe related to https://github.com/plataformatec/nimble_parsec/issues/53
  @dialyzer [:no_return, :no_opaque]

  # ----- lex items ----- #
  def root, do: ignore(string("$"))
  def dot, do: ignore(string("."))
  def dot_dot, do: ignore(string(".."))
  def star, do: string("*") |> replace(Tag.wildcard())

  def convert_integer([int]), do: int
  def convert_integer(["-", int]), do: -1 * int

  def possibly_neg_integer do
    optional(string("-"))
    |> integer(min: 1)
    |> reduce({__MODULE__, :convert_integer, []})
    |> label("integer expression")
  end

  def atom_expression do
    ignore(string(":"))
    |> choice([
      choice([qq_string(), q_string()]),
      unquoted_atom_id()
    ])
    |> post_traverse({Elixpath.Parser.Atom, :post_traverse_atom, [_add_opts = []]})
    |> label("atom expression")
  end

  def unquoted_atom_id do
    ascii_string([?a..?z, ?A..?Z, ?_], 1)
    |> optional(ascii_string([?a..?z, ?A..?Z, ?0..?9, ?_, ?@], min: 1))
    |> optional(ascii_string([?a..?z, ?A..?Z, ?0..?9, ?_, ?@, ??, ?!], 1))
    |> reduce({Enum, :join, []})
    |> label("unquoted atom expression")
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

  defp single_escaped_char do
    ignore(string("\\"))
    |> ascii_string([], 1)
    |> map({__MODULE__, :map_escaped, []})
  end

  defp escaped_with_x do
    ignore(string("\\x"))
    |> ascii_string([?0..?9, ?a..?f, ?A..?F], 2)
    |> map({String, :to_integer, [16]})
    |> label("\\xHH")
  end

  defp escaped_with_u_brace do
    ignore(string("\\u{"))
    |> ascii_string([?0..?9, ?a..?f, ?A..?F], min: 1)
    |> ignore(string("}"))
    |> map({String, :to_integer, [16]})
    |> label("\\u{HHH...}")
  end

  defp escaped_with_u_raw do
    ignore(string("\\u"))
    |> ascii_string([?0..?9, ?a..?f, ?A..?F], 4)
    |> map({String, :to_integer, [16]})
    |> label("\\u{HHHH}")
  end

  def qq_string do
    ignore(string(~S/"/))
    |> repeat(
      choice([
        escaped_with_x(),
        escaped_with_u_brace(),
        escaped_with_u_raw(),
        single_escaped_char(),
        utf8_char([{:not, ?"}])
      ])
    )
    |> ignore(string(~S/"/))
    |> reduce({List, :to_string, []})
    |> label("double-quoted string")
  end

  def q_string do
    ignore(string(~S/'/))
    |> repeat(
      choice([
        escaped_with_x(),
        escaped_with_u_brace(),
        escaped_with_u_raw(),
        single_escaped_char(),
        utf8_char([{:not, ?'}])
      ])
    )
    |> ignore(string(~S/'/))
    |> reduce({List, :to_string, []})
    |> label("single-quoted string")
  end

  def post_traverse_string_or_atom(_rest, [result], context, _line, _offset, additional_opts) do
    opts = additional_opts ++ Map.get(context, :opts, [])
    prefer_keys = Keyword.get(opts, :prefer_keys, :string)

    case prefer_keys do
      :string ->
        {[result], context}

      :atom ->
        with {:ok, atom} <- Elixpath.Parser.Atom.to_atom(result, opts) do
          {[atom], context}
        end
    end
  end

  def unquoted_string_or_atom do
    utf8_string([{:not, ?.}, {:not, ?[}, {:not, ?]}], min: 1)
    |> lookahead(choice([string("."), string("["), string("]"), eos()]))
    |> post_traverse({__MODULE__, :post_traverse_string_or_atom, [_opts = []]})
  end

  # ----- BNFs ----- #
  def path do
    choice([
      root() |> eos(),
      root() |> times(path_component(), min: 1) |> eos(),
      times(path_component(), min: 1) |> eos(),
      first_child_member_component() |> repeat(path_component()) |> eos()
    ])
  end

  def path_component do
    choice([
      member_component(),
      subscript_component()
    ])
  end

  def member_component do
    choice([
      child_member_component(),
      descendant_member_component()
    ])
  end

  def child_member_component do
    dot() |> concat(member_expression()) |> unwrap_and_tag(Tag.child())
  end

  def first_child_member_component do
    member_expression() |> unwrap_and_tag(Tag.child())
  end

  def descendant_member_component do
    dot_dot() |> concat(member_expression()) |> unwrap_and_tag(Tag.descendant())
  end

  def member_expression do
    choice([
      star(),
      possibly_neg_integer(),
      atom_expression(),
      q_string(),
      qq_string(),
      unquoted_string_or_atom()
    ])
    |> lookahead(choice([string("."), string("["), eos()]))
    |> label("member_expression")
  end

  def subscript_component do
    choice([
      child_subscript_component(),
      descendant_subscript_component()
    ])
  end

  def child_subscript_component do
    ignore(string("["))
    |> concat(subscript_expression())
    |> ignore(string("]"))
    |> unwrap_and_tag(Tag.child())
    |> label("[(subscript_expression)]")
  end

  def descendant_subscript_component do
    dot_dot()
    |> ignore(string("["))
    |> concat(subscript_expression())
    |> ignore(string("]"))
    |> unwrap_and_tag(Tag.descendant())
    |> label("..[(subscript_expression)]")
  end

  def subscript_expression do
    choice([
      star(),
      possibly_neg_integer(),
      atom_expression(),
      q_string(),
      qq_string(),
      unquoted_string_or_atom()
    ])
  end
end
