defmodule Elixpath.PathComponent do
  @moduledoc """
  Path components to form an Elixpath.
  Defined as macros for use in guards and pattern matching.
  """

  require Elixpath.Tag, as: Tag

  @type t :: child | descendant
  @type child :: {Tag.child(), key}
  @type descendant :: {Tag.descendant(), key}
  @type key :: term

  @doc """
  Child path component, e.g. Map/Keyword value or list element.
  """
  defmacro child(x), do: {Tag.child(), x}

  @doc """
  Descendant path component, recursively including children, grand-children, and so on.
  """
  defmacro descendant(x), do: {Tag.descendant(), x}
end
