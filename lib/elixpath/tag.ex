defmodule Elixpath.Tag do
  defmacro child, do: :elixpath_child
  defmacro descendant, do: :elixpath_descendant
  defmacro wildcard, do: :elixpath_wildcard
end
