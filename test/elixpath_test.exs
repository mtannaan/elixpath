defmodule ElixpathTest do
  use ExUnit.Case
  doctest Elixpath

  # for sigils
  import Elixpath

  test "get from maps with string key" do
    deepmap = %{"k1" => %{"k21" => "v1", 'k22' => :v2}}
    assert Elixpath.get!(deepmap, ~S/."k1"."k21"/) === "v1"
    assert Elixpath.query!(deepmap, ~S/."k1".'k22'/) === [:v2]

    assert Elixpath.query!(deepmap, ~S/."non-existing key"/) === []
  end

  test "get from maps with atom key" do
    deepmap = %{k1: %{k21: "v1", k22: :v2}}
    assert Elixpath.get!(deepmap, ".:k1.:k21") === "v1"
    assert Elixpath.query!(deepmap, ".:k1.:k22") === [:v2]

    assert Elixpath.query(deepmap, ".:non_existing_key") |> elem(0) === :error

    :nonsense
    assert Elixpath.query!(deepmap, ".:nonsense") === []
  end

  test "get all from map" do
    deepmap = %{"k1" => %{"k11" => "v11", "k12" => :v12}, "k2" => :v2}
    assert Elixpath.query!(deepmap, ~S/."k1".*/) === ["v11", :v12]
    assert Elixpath.query!(deepmap, ~S/.*."k11"/) === ["v11"]
  end

  test "get descendant from map" do
    deepmap = %{"k1" => %{"k21" => "v1", "k22" => :v2}}
    assert Elixpath.get!(deepmap, ~S/.."k21"/) === "v1"
    assert Elixpath.query!(deepmap, ~S/..*/) === [%{"k21" => "v1", "k22" => :v2}, "v1", :v2]
    assert Elixpath.query!(deepmap, ~S/..*."k22"/) === [:v2]
  end

  test "get by list index" do
    deeplist = [0, 1, 2, 3, [40, 41, [420, 421]], 5]
    assert Elixpath.query!(deeplist, ".0") === [0]
    assert Elixpath.query!(deeplist, ".99") === []
    assert Elixpath.query!(deeplist, ".-2") === [[40, 41, [420, 421]]]
    assert Elixpath.query!(deeplist, ".4.1") === [41]
    assert Elixpath.query!(deeplist, ".-2.*") === [40, 41, [420, 421]]
    assert Elixpath.query!(deeplist, "..1") === [1, 41, 421]
    assert Elixpath.query!(deeplist, "..99") === []
  end

  test "get from keywords" do
    deepkw = [k1: :v1, k2: [k21: :v21, k22: [k221: :v221, k222: :v222]]]
    assert Elixpath.query!(deepkw, ".:k1") === [:v1]
    assert Elixpath.query!(deepkw, ".:k2.:k21") === [:v21]
    assert Elixpath.query!(deepkw, "..:k221") === [:v221]
    assert Elixpath.query!(deepkw, "..:k22.*") === [:v221, :v222]
  end

  test "sigil_p" do
    deepmap = %{"k1" => %{"k21" => "v1", k22: :v2}}
    assert Elixpath.get!(deepmap, ~p/."k1"."k21"/) === "v1"
    assert Elixpath.get!(deepmap, ~p/..:k22/) === :v2
    assert Elixpath.get!(deepmap, ~p/..k22/) === nil
    assert Elixpath.get!(deepmap, ~p/..k22/a) === :v2
    assert Elixpath.query(deepmap, ~p/..:_______non_existing/u) === {:ok, []}
  end
end
