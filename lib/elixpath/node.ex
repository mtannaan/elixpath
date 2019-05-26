defmodule Elixpath.Node do
  require Elixpath.Tag, as: Tag
  defmacro child(x), do: {Tag.child(), x}
  defmacro descendant(x), do: {Tag.descendant(), x}
  defmacro wildcard(x), do: {Tag.wildcard(), x}
end
