defmodule ElixpathTest.Parser do
  use ExUnit.Case, async: false
  doctest Elixpath.Parser

  import Elixpath.PathComponent
  import Elixpath.Parser
  require Elixpath.Tag, as: Tag

  test "root" do
    assert path("$") === {:ok, []}
  end

  test "integer" do
    assert path!(~S/1.2.3/) === [child(1), child(2), child(3)]
    assert path!(~S/$.1..2.3/) === [child(1), descendant(2), child(3)]
    assert path!(~S/$[1].2[3]/) === [child(1), child(2), child(3)]
    assert path!(~S/$[1]..[2][3]/) === [child(1), descendant(2), child(3)]
    assert path!(~S/$..[1]..[2]..[3]/) === [descendant(1), descendant(2), descendant(3)]
  end

  @tag :abnormal
  test "non-existing atom" do
    assert_raise Elixpath.Parser.ParseError, ~r/error parsing path/, fn ->
      path!(~S/:______non_existing_atom_______/)
    end
  end

  @tag :abnormal
  test "too long atom" do
    assert_raise Elixpath.Parser.ParseError,
                 ~r/error parsing path.+atom length must be less than system limit/,
                 fn ->
                   path!(
                     ~S/:loooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooong_atom/,
                     unsafe_atom: true
                   )
                 end
  end

  test "atom" do
    assert path!(~S/:a/) === [child(:a)]
    assert path!(~S/$[:a]/) === [child(:a)]
    assert path!(~S/:a.:"2".:c/) === [child(:a), child(:"2"), child(:c)]
    assert path!(~S/$..[:a].:"bbb"[:CCC]/) === [descendant(:a), child(:bbb), child(:CCC)]
    assert path(~S/:______non_existing_atom_____/, unsafe_atom: true) |> elem(0) === :ok
  end

  test "double-quoted string" do
    assert path!(~S/"a"/) === [child("a")]
    assert path!(~S/"\\"/) === [child("\\")]
    assert path!(~S/$["a"]/) === [child("a")]
    assert path!(~S/"a"."2"."c"/) === [child("a"), child("2"), child("c")]

    assert path!(~S/"a".."2\x62b\u65e5\u{672c}\u8A9e"["3c"]/) === [
             child("a"),
             descendant("2bb日本語"),
             child("3c")
           ]

    assert path!(~S/$..["a"]."bb\nb"["CCC"]/) === [descendant("a"), child("bb\nb"), child("CCC")]
  end

  test "wildcard" do
    assert path!(~S/.*/) === [child(Tag.wildcard())]
    assert path!(~S/$[*].1/) === [child(Tag.wildcard()), child(1)]
  end

  test "unquoted" do
    assert path!(~S/.asdf[erty]..qwer/) === [child("asdf"), child("erty"), descendant("qwer")]

    assert path!(~S/.as[er]..qw/, prefer_keys: :atom) === [
             child(:as),
             child(:er),
             descendant(:qw)
           ]
  end
end
