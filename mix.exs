defmodule DistributedPerformanceAnalyzer.MixProject do
  use Mix.Project

  def project do
    [
      app: :distributed_performance_analyzer,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      escript: [
        main_module: Cli.CommandLine
      ],
      test_coverage: [
        tool: ExCoveralls,
        # TODO: increase project coverage
        summary: [threshold: 25]
      ],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.xml": :test
      ],
      deps: deps(),
      metrics: true
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :opentelemetry_exporter, :opentelemetry],
      mod: {DistributedPerformanceAnalyzer.Application, [Mix.env()]}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:sobelow, "~> 0.11", only: :dev},
      {:credo_sonarqube, "~> 0.1"},
      {:finch, "~> 0.13"},
      {:opentelemetry_plug,
       git: "https://github.com/juancgalvis/opentelemetry_plug.git", tag: "master"},
      {:opentelemetry_api, "~> 1.0"},
      {:opentelemetry_exporter, "~> 1.5"},
      {:telemetry, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:telemetry_metrics_prometheus, "~> 1.0"},
      {:distillery, "~> 2.1"},
      {:castore, "~> 1.0"},
      {:plug_cowboy, "~> 2.6"},
      {:jason, "~> 1.0"},
      {:plug_checkup, "~> 0.6"},
      {:poison, "~> 5.0"},
      {:cors_plug, "~> 3.0"},
      {:excoveralls, "~> 0.16", only: :test},
      {:ex_unit_sonarqube, "~> 0.1", only: :test},
      {:constructor, "~> 1.1"},
      {:nimble_csv, "~> 1.2"},
      {:file_size, "~> 3.0"},
      {:mint, "~> 1.5"},
      {:git_hooks, "~> 0.7.3", only: [:dev], runtime: false}
    ]
  end
end
