defmodule ExUnitParameterize.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_unit_parameterize,
      version: "0.1.0-alpha.2",
      elixir: "~> 1.14",
      deps: deps(),
      package: [
        name: "ex_unit_parameterize",
        maintainers: ["Radu Ciorba"],
        licenses: ["MIT"],
        links: %{"GitHub" => "https://github.com/rciorba/ex_unit_parameterize"}
      ],
      description: description(),
      # Docs
      name: "ExUnitParameterize",
      source_url: "https://github.com/rciorba/ex_unit_parameterize",
      homepage_url: "https://github.com/rciorba/ex_unit_parameterize",
      docs: [
        main: "readme", # The main page in the docs
        extras: ["README.md"]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application, do: []

  defp description() do
    "Parameterized tests for ExUnit."
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.31", only: :dev, runtime: false}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
