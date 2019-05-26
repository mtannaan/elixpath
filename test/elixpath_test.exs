defmodule ElixpathTest do
  use ExUnit.Case
  doctest Elixpath

  test "get from maps with string key" do
    deepmap = %{"k1" => %{"k21" => "v1", "k22" => :v2}}
    assert Elixpath.get(deepmap, ".'k1'.'k21'") === "v1"
    assert Elixpath.get(deepmap, ".'k1'.'k22'") === :v2

    assert Elixpath.get(deepmap, ".'non-existing key'") === nil
  end

  test "get from maps with atom key" do
    deepmap = %{k1: %{k21: "v1", k22: :v2}}
    assert Elixpath.get(deepmap, ".:k1.:k21") === "v1"
    assert Elixpath.get(deepmap, ".:k1.:k22") === :v2
    assert Elixpath.get(deepmap, ".:non_existing_key") === nil
  end
end
