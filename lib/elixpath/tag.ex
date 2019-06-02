defmodule Elixpath.Tag do
  @moduledoc """
  Constants used to represent each path component.
  Defined as macros for use in guards and pattern matching.
  """

  @type child :: :elixpath_child
  @type descendant :: :elixpath_descendant
  @type wildcard :: :elixpath_wildcard

  defmacro child, do: :elixpath_child
  defmacro descendant, do: :elixpath_descendant

  @doc """
  Used in combination with `child/0` or `descendant/0`,
  e.g. `Elixpath.PathComponent.child(Elixpath.Tag.wildcard())` represents "all the children."
  """
  defmacro wildcard, do: :elixpath_wildcard
end
