defmodule Elixpath.Parser do
  import NimbleParsec
  require Elixpath.Tag, as: Tag

  defmodule Components do
    # ----- lex items ----- #
    def root, do: ignore(string("$"))
    def dot, do: ignore(string("."))
    def dot_dot, do: ignore(string(".."))
    def star, do: string("*") |> replace(Tag.wildcard())

    def identifier do
      utf8_string([?a..?z, ?A..?Z, ?_], 1)
      |> utf8_string([?a..?z, ?A..?Z, ?0..?9, ?_], min: 1)
      |> reduce({Enum, :join, []})
      |> label("identifier")
    end

    def handle_neg_integer([int]), do: int
    def handle_neg_integer(["-", int]), do: -1 * int

    def possibly_neg_integer do
      optional(string("-")) |> integer(min: 1) |> reduce({__MODULE__, :handle_neg_integer, []})
    end

    def atom_expression do
      ignore(string(":"))
      |> choice([
        choice([qq_string(), q_string()]),
        Elixpath.Parser.Atom.non_quoted_atom()
      ])
    end

    def non_quoted_atom do
      # FIXME
      utf8_string([], min: 1)
    end

    def map_escaped(~S/"/), do: ~S/"/
    def map_escaped("b"), do: "\b"
    def map_escaped("f"), do: "\f"
    def map_escaped("n"), do: "\n"
    def map_escaped("r"), do: "\r"
    def map_escaped("t"), do: "\t"

    def qq_string do
      ignore(string(~S/"/))
      |> repeat(
        choice([
          ignore(string("\\"))
          |> ascii_string('"bfnrt', 1)
          |> map({__MODULE__, :map_escaped, []}),
          utf8_string([{:not, ?"}], 1)
        ])
      )
      |> ignore(string(~S/"/))
      |> reduce({Enum, :join, []})
      |> label("double-quoted string")
    end

    def q_string do
      ignore(string(~S/'/))
      |> repeat(
        choice([
          ignore(string("\\"))
          |> ascii_string('\'bfnrt', 1)
          |> map({__MODULE__, :map_escaped, []}),
          utf8_string([{:not, ?'}], 1)
        ])
      )
      |> ignore(string(~S/'/))
      |> reduce({Enum, :join, []})
      |> label("single-quoted string")
    end

    # ----- BNFs ----- #
    def path do
      choice([
        root(),
        optional(root()) |> repeat(path_component())
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

    def descendant_member_component do
      dot_dot() |> concat(member_expression()) |> unwrap_and_tag(Tag.descendant())
    end

    def member_expression do
      choice([
        star(),
        possibly_neg_integer(),
        atom_expression()
      ])
      |> lookahead(choice([string("."), string("["), eos()]))
    end

    def subscript_component do
      choice([
        child_subscript_component(),
        descendant_subscript_component()
      ])
    end

    def child_subscript_component do
      ignore(string("["))
      |> concat(subscript())
      |> ignore(string("]"))
      |> unwrap_and_tag(Tag.child())
    end

    def descendant_subscript_component do
      dot_dot()
      |> ignore(string("["))
      |> concat(subscript())
      |> ignore(string("]"))
      |> unwrap_and_tag(Tag.descendant())
    end

    def subscript do
      choice([
        subscript_expression(),
        subscript_expression_list()
      ])
    end

    def subscript_expression_list do
      # TODO: list support: times(subscript_expression_listable(), min: 1)
      subscript_expression_listable()
    end

    def subscript_expression_listable do
      # TODO: array_slice support
      choice([
        possibly_neg_integer(),
        string_literal()
      ])
    end

    def subscript_expression do
      # TODO: script_expression & filter_expression support
      star()
    end

    def string_literal do
      # TODO: q_string support
      qq_string()
    end
  end

  defparsecp(:parse_path, Components.path())

  def path!(str) do
    {:ok, result, "", _context, _line, _column} = parse_path(str)
    result
  end
end
