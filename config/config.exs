import Config

config :git_hooks,
  auto_install: true,
  hooks: [
    pre_commit: [
      verbose: true,
      tasks: [
        {:file, "./hooks/mix_format"},
        {:mix_task, :format, ["--check-formatted", "--dry-run"]},
        {:mix_task, :test, ["--color", "--cover"]},
        {:mix_task, :sobelow}
        #        {:mix_task, :credo}
      ]
    ]
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
  file_system_behaviour: DistributedPerformanceAnalyzer.Domain.Behaviours.FileSystemBehaviour,
  dataset_parser: DistributedPerformanceAnalyzer.Infrastructure.Adapters.FileSystem.Parser

import_config "#{Mix.env()}.exs"
