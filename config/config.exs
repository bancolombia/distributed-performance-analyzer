import Config

config :git_hooks,
  auto_install: true,
  hooks: [
    pre_commit: [
      verbose: true,
      tasks: [
        {:file, "./hooks/mix_format"},
        {:cmd, "mix coveralls.xml"}
        # {:mix_task, :format, ["--check-formatted", "--dry-run"]},
        # {:mix_task, :credo}
      ]
    ]
    # pre_push: [
    #   verbose: false,
    #   tasks: [
    #     {:cmd, "mix dialyzer"},
    #     {:cmd, "mix test --color"},
    #     {:cmd, "echo 'success!'"}
    #   ]
    # ]
  ]

config :distributed_performance_analyzer,
  timezone: "America/Bogota",
  http_port: 8083,
  enable_server: true,
  secret_name: "",
  region: "",
  version: "0.0.1",
  in_test: false,
  custom_metrics_prefix_name: "distributed_performance_analyzer_local",
  dataset_parser: DistributedPerformanceAnalyzer.Infrastructure.Adapters.FileSystem.Parser,
  report_csv: DistributedPerformanceAnalyzer.Infrastructure.Adapters.OutputCsv

import_config "#{Mix.env()}.exs"
