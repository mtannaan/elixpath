# Elixpath

Extract data from possibly deeply-nested Elixir data structure using JSONPath-like path expressions.

## Searching for XPath?
If you are planning to manipulate XML document directly, other packages like [sweet_xml](https://hex.pm/packages/sweet_xml) can be better choices.

## Elixpath expression
Elixpath's path expression is based on [JSONPath](https://goessner.net/articles/JsonPath/),
while mainly with following differences:

* Elixir's String and atom can be directly specified, e.g. `."string".:atom`
* Several JSONPath features like following are not supported:
    - "current object" syntax element: `@`
    - union subscript operator: `[xxx,yyy]`
    - array slice operator: `[start:end:stop]`
    - filter and script expression using `()`

## Path Syntax

Elixpath is represented by a sequence of following path components.
* `$` - root object. Optional. When present, this component has to be at the beginning of the path.
* `.(key expression)` or `[(key expression)]` - child objects that matches the given key.
* `..(key expression)` - descendant objects that matches the given key.

`(key expression)` above can be either of:
* *integer* - used to specify index in lists. Value can be negative, e.g. `-1` represents the last element.
* *atom* - starts with colon and can be quoted, e.g. `:atom`, `:"quoted_atom"`. 
  When `prefer_keys: :atom` option is given, preceding colon can be omitted.
* *string* - double-quoted. Double quotation can be omitted unless `prefer_keys: :atom` option is given.
* *charlist* - single-quoted. 
* *wildcard* - `*`. Represents all the children.

## Examples
```elixir
# string
iex> Elixpath.query(%{:a => 1, "b" => 2}, ~S/."b"/)
{:ok, [2]}

# unquoted string
iex> Elixpath.query(%{:a => 1, "b" => 2}, ".b")
{:ok, [2]}

# no match
iex> Elixpath.query(%{:a => 1, "b" => 2}, ".nonsense")
{:ok, []}

# atom
iex> Elixpath.query(%{:a => 1, "b" => 2}, ".:a")
{:ok, [1]}

# integer
iex> Elixpath.query(%{:a => [%{b: 2}, %{c: 3}]}, ".:a[-1]")
{:ok, [%{c: 3}]}

# descendant
iex> Elixpath.query(%{:a => [%{b: 2}, %{c: 3}]}, "..:c")
{:ok, [3]}

# wildcard
iex> Elixpath.query(%{:a => [%{b: 2}, %{c: 3}]}, ".*.*.*")
{:ok, [2, 3]}

# enable sigil_p, which runs compile-time check and transformation for Elixpath
iex> import Elixpath
iex> Elixpath.query(%{:a => [%{b: 2}, %{c: 3}]}, ~p".:a.1.:c")
{:ok, [3]}

# path syntax error for normal string is detected at runtime.
iex> Elixpath.query(%{:a => [%{b: 2}, %{c: 3}]}, ".:atom:syntax:error")
{:error, "expected member_expression while processing path"}

# while sigil_p raises compilation error:
# iex> Elixpath.query(%{:a => [%{b: 2}, %{c: 3}]}, ~p".:atom:syntax:error")
# == Compilation error in file test/elixpath_test.exs ==
# ** (Elixpath.Parser.ParseError) ...
```