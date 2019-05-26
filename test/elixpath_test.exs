defmodule ElixpathTest do
  use ExUnit.Case
  doctest Elixpath

  test "get from maps with string key" do
    deepmap = %{"k1" => %{"k21" => "v1", "k22" => :v2}}
    assert Elixpath.get!(deepmap, ".'k1'.'k21'") === "v1"
    assert Elixpath.fetch_all!(deepmap, ".'k1'.'k22'") === [:v2]

    assert Elixpath.fetch_all!(deepmap, ".'non-existing key'") === []
  end

  test "get from maps with atom key" do
    deepmap = %{k1: %{k21: "v1", k22: :v2}}
    assert Elixpath.get!(deepmap, ".:k1.:k21") === "v1"
    assert Elixpath.fetch_all!(deepmap, ".:k1.:k22") === [:v2]

    assert Elixpath.fetch_all(deepmap, ".:non_existing_key") |> elem(0) === :error

    :nonsense
    assert Elixpath.fetch_all!(deepmap, ".:nonsense") === []
  end

  test "get all from map" do
    deepmap = %{"k1" => %{"k11" => "v11", "k12" => :v12}, "k2" => :v2}
    assert Elixpath.fetch_all!(deepmap, ~S/."k1".*/) === ["v11", :v12]
    assert Elixpath.fetch_all!(deepmap, ~S/.*."k11"/) === ["v11"]
  end

  test "get descendant from map" do
    deepmap = %{"k1" => %{"k21" => "v1", "k22" => :v2}}
    assert Elixpath.get!(deepmap, ~S/.."k21"/) === "v1"
    assert Elixpath.fetch_all!(deepmap, ~S/..*/) === [%{"k21" => "v1", "k22" => :v2}, "v1", :v2]
    assert Elixpath.fetch_all!(deepmap, ~S/..*."k22"/) === [:v2]
  end
end
