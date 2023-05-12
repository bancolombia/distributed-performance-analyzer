defmodule DistributedPerformanceAnalyzer.MixProject do
  use Mix.Project

  def project do
    [
      app: :distributed_performance_analyzer,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      escript: [
        main_module: Cli.CommandLine
      ],
      test_coverage: [
        tool: ExCoveralls,
        # TODO: increase project coverage
        summary: [threshold: 34]
      ],
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {DistributedPerformanceAnalyzer.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:finch, "~> 0.13"},
      {:opentelemetry_plug,
       git: "https://github.com/juancgalvis/opentelemetry_plug.git",
       ref: "82206fb09fbeb9ffa2f167a5f58ea943c117c003",
       override: true},
      {:opentelemetry_api, "~> 0.6.0", override: true},
      {:opentelemetry_exporter, "~> 0.6.0"},
      {:telemetry, "~> 1.0", override: true},
      {:telemetry_poller, "~> 0.5.1"},
      {:telemetry_metrics_prometheus, "~> 1.1.0"},
      {:distillery, "~> 2.1"},
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      {:castore, "~> 0.1.0"},
      {:plug_cowboy, "~> 2.2"},
      {:jason, "~> 1.0"},
      {:plug_checkup, "~> 0.6.0"},
      {:poison, "~> 4.0"},
      {:cors_plug, "~> 2.0"},
      {:excoveralls, "~> 0.10", only: :test},
      {:ex_unit_sonarqube, "~> 0.1", only: :test},
      {:constructor, "~> 1.1"},
      {:nimble_csv, "~> 1.2"},
      {:file_size, "~> 3.0"},
      {:mint, "~> 1.5"},
      {:git_hooks, "~> 0.7.3", only: [:dev], runtime: false}
    ]
  end
end
