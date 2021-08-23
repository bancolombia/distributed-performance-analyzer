defmodule PerfAnalyzer.MixProject do
  use Mix.Project

  def project do
    [
      app: :perf_analizer,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      escript: [
        main_module: Cli.CommandLine
      ],
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :httpoison],
      mod: {Perf.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:castore, "~> 0.1.11"},
      {:mint, "~> 1.3.0"},
      {:httpoison, "~> 1.8"},
      {:poison, "~> 5.0"},
      {:distillery, "~> 2.1"}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
