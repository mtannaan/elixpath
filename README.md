# Elixpath
[![Build Status](https://travis-ci.com/mtannaan/elixpath.svg?branch=master)](https://travis-ci.com/mtannaan/elixpath) [![codecov](https://codecov.io/gh/mtannaan/elixpath/branch/master/graph/badge.svg)](https://codecov.io/gh/mtannaan/elixpath) [![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/mtannaan/elixpath/blob/master/LICENSE) [![Hex.pm](https://img.shields.io/hexpm/v/elixpath.svg)](https://hex.pm/packages/elixpath)

Extract data from Elixir's native data structure using JSONPath-like path expressions.

## Searching for XPath Tools?
If you are planning to manipulate XML documents directly, other packages like [sweet_xml](https://hex.pm/packages/sweet_xml) can be better choices.

## Elixpath Expression
Elixpath's path expression is based on [JSONPath](https://goessner.net/articles/JsonPath/),
but mainly with following differences:

* Following Elixir's native expressions are supported:
    - String, e.g. `..string."double-quoted string"`
    - Atom, e.g. `.:atom.:"quoted atom"`
    - Charlist, e.g. `.'single-quoted'`
    - Integer, e.g. `[1][-1]`
* Several JSONPath features like following are not supported:
    - "Current object" syntax element: `@`
    - Union subscript operator: `[xxx,yyy]`
    - Array slice operator: `[start:end:stop]`
    - Filter and script expression using `()`

## Path Syntax

An Elixpath is represented by a sequence of following path components.
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

# you can use Elixpath.get! if you want only a single match
iex> Elixpath.get!(%{:a => 1, "b" => 2}, ".*")          
1

# unquoted string
iex> Elixpath.query(%{:a => 1, "b" => 2}, ".b")
{:ok, [2]}

# no match
iex> Elixpath.query(%{:a => 1, "b" => 2}, ".nonsense")
{:ok, []}

# no match w/ get!
iex> Elixpath.get!(%{:a => 1, "b" => 2}, ".nonsense", _default = :some_default_value)
:some_default_value

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

# enable sigil_p/2, which parses Elixpath at compile time.
iex> import Elixpath
iex> Elixpath.query(%{:a => [%{b: 2}, %{c: 3}]}, ~p".:a.1.:c")
{:ok, [3]}

# path syntax error for normal string is detected at runtime.
iex> Elixpath.query(%{:a => [%{b: 2}, %{c: 3}]}, ".:atom:syntax:error")
{:error, "expected member_expression while processing path"}

# while sigil_p raises a compilation error:
# iex> Elixpath.query(%{:a => [%{b: 2}, %{c: 3}]}, ~p".:atom:syntax:error")
# == Compilation error in file test/elixpath_test.exs ==
# ** (Elixpath.Parser.ParseError) ...
```