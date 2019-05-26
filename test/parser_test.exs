defmodule ElixpathTest.Parser do
  use ExUnit.Case
  doctest Elixpath.Parser

  import Elixpath.Node
  import Elixpath.Parser, only: [path!: 1]

  test "root" do
    assert path!("$") === []
  end

  test "integer" do
    assert path!(~S/1.2.3/) === [child(1), child(2), child(3)]
    assert path!(~S/$.1..2.3/) === [child(1), descendant(2), child(3)]
    assert path!(~S/$[1].2[3]/) === [child(1), child(2), child(3)]
    assert path!(~S/$[1]..[2][3]/) === [child(1), descendant(2), child(3)]
    assert path!(~S/$..[1]..[2]..[3]/) === [descendant(1), descendant(2), descendant(3)]
  end

  test "atom" do
    assert path!(~S/:a/) === [child(:a)]
    assert path!(~S/$[:a]/) === [child(:a)]
    assert path!(~S/:a.:"2".:c/) === [child(:a), child(:"2"), child(:c)]
    assert path!(~S/:a..:"2bb"[:"3c"]/) === [child(:a), descendant(:"2bb"), child(:"3c")]
    assert path!(~S/$..[:a].:"bbb"[:CCC]/) === [descendant(:a), child(:bbb), child(:CCC)]
  end
end
