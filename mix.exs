defmodule Elixpath.MixProject do
  use Mix.Project

  def project do
    [
      app: :elixpath,
      version: "0.1.1",
      elixir: ">= 1.7.0",
      start_permanent: Mix.env() == :prod,
      description: description(),
      deps: deps(),
      package: package(),
      docs: [main: "readme", extras: ["README.md"]],
      test_coverage: [tool: ExCoveralls]
    ]
  end

  def description do
    "JSONPath-like operations for Elixir's native data structure"
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
      {:nimble_parsec, "~> 0.5 or ~>1.0", runtime: false},
      {:ex_doc, "~>0.28", only: [:dev], runtime: false},
      {:excoveralls, "~> 0.14.6", only: [:test]},
      # ---
      # dependency :ssl_verify needs this for compilation
      # https://github.com/edgurgel/httpoison/issues/46
      {:ssl_verify_fun, ">= 0.0.0", manager: :rebar3, override: true}
    ]
  end

  # Hex package info
  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/mtannaan/elixpath"}
    ]
  end
end
