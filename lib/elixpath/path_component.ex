defmodule Elixpath.PathComponent do
  @moduledoc """
  Path components to form Elixpath.
  Defined as macros for using in guards and pattern matching.
  """

  require Elixpath.Tag, as: Tag

  @type t :: child | descendant
  @type child :: {Tag.child(), key}
  @type descendant :: {Tag.descendant(), key}
  @type key :: term

  @doc """
  Child path component.
  E.g. Map/Keyword value or list element.
  """
  defmacro child(x), do: {Tag.child(), x}

  @doc """
  Descendant path component, recursively including children, grand-children, and so on.
  """
  defmacro descendant(x), do: {Tag.descendant(), x}
end
