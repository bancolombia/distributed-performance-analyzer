defmodule PerfAnalyzer.MixProject do
  use Mix.Project

  def project do
    [
      app: :perf_analyzer,
      version: "0.3.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      escript: [
        main_module: Cli.CommandLine
      ],
      test_coverage: [
        summary: [threshold: 34] # TODO: increase project coverage
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
      {:castore, "~> 0.1.18"},
      {:mint, "~> 1.4"},
      {:httpoison, "~> 1.8"},
      {:poison, "~> 5.0"},
      {:distillery, "~> 2.1"},
      {:nimble_csv, "~> 1.2"},
      {:file_size, "~> 3.0"},
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
