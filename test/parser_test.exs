defmodule ElixpathTest.Parser do
  use ExUnit.Case, async: false
  doctest Elixpath.Parser

  import Elixpath.PathComponent
  import Elixpath.Parser
  require Elixpath.Tag, as: Tag

  test "root" do
    assert parse("$") === {:ok, %Elixpath{path: []}}
  end

  test "integer" do
    assert parse!(~S/1.2.3/).path === [child(1), child(2), child(3)]
    assert parse!(~S/$.1..2.3/).path === [child(1), descendant(2), child(3)]
    assert parse!(~S/$[1].2[3]/).path === [child(1), child(2), child(3)]
    assert parse!(~S/$[1]..[2][3]/).path === [child(1), descendant(2), child(3)]
    assert parse!(~S/$..[1]..[2]..[3]/).path === [descendant(1), descendant(2), descendant(3)]
  end

  @tag :abnormal
  test "non-existing atom" do
    assert_raise Elixpath.Parser.ParseError, ~r/error parsing path/, fn ->
      parse!(~S/:______non_existing_atom_______/)
    end
  end

  @tag :abnormal
  test "too long atom" do
    assert_raise Elixpath.Parser.ParseError,
                 ~r/error parsing path.+atom length must be less than system limit/,
                 fn ->
                   parse!(
                     ~S/:loooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooong_atom/,
                     unsafe_atom: true
                   )
                 end
  end

  test "atom" do
    assert parse!(~S/:a/).path === [child(:a)]
    assert parse!(~S/$[:a]/).path === [child(:a)]
    assert parse!(~S/:a.:"2".:c/).path === [child(:a), child(:"2"), child(:c)]
    assert parse!(~S/$..[:a].:"bbb"[:CCC]/).path === [descendant(:a), child(:bbb), child(:CCC)]
    assert parse(~S/:______non_existing_atom_____/, unsafe_atom: true) |> elem(0) === :ok
  end

  test "double-quoted string" do
    assert parse!(~S/"a"/).path === [child("a")]
    assert parse!(~S/"\\"/).path === [child("\\")]
    assert parse!(~S/$["a"]/).path === [child("a")]
    assert parse!(~S/"a"."2"."c"/).path === [child("a"), child("2"), child("c")]

    assert parse!(~S/"a".."2\x62b\u65e5\u{672c}\u8A9e"["3c"]/).path === [
             child("a"),
             descendant("2bb日本語"),
             child("3c")
           ]

    assert parse!(~S/$..["a"]."bb\nb"["CCC"]/).path === [
             descendant("a"),
             child("bb\nb"),
             child("CCC")
           ]
  end

  test "wildcard" do
    assert parse!(~S/.*/).path === [child(Tag.wildcard())]
    assert parse!(~S/$[*].1/).path === [child(Tag.wildcard()), child(1)]
  end

  test "unquoted" do
    assert parse!(~S/.asdf[erty]..qwer/).path === [
             child("asdf"),
             child("erty"),
             descendant("qwer")
           ]

    assert parse!(~S/.as[er]..qw/, prefer_keys: :atom).path === [
             child(:as),
             child(:er),
             descendant(:qw)
           ]
  end
end
