defmodule Parameterize.MixProject do
  use Mix.Project

  def project do
    [
      app: :parameterize,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      description: description()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    []
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      {:ex_doc, "~> 0.22", only: [:dev], runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["Radu Ciorba"],
      licenses: ["Public Domain"],
      links: %{"GitHub" => "https://github.com/rciorba/yapara"}
    ]
  end

  defp description do
    """
    Yet another library for parameterized tests with ExUnit.
    """
  end
end
