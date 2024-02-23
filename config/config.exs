import Config

config :distributed_performance_analyzer,
  timezone: "America/Bogota",
  http_port: 8083,
  enable_server: true,
  secret_name: "",
  region: "",
  version: "0.0.1",
  in_test: false,
  custom_metrics_prefix_name: "distributed_performance_analyzer_local",
  dataset_parser: DistributedPerformanceAnalyzer.Infrastructure.Adapters.Csv,
  file_system: DistributedPerformanceAnalyzer.Infrastructure.Adapters.FileSystem,
  report_exporter: DistributedPerformanceAnalyzer.Infrastructure.Adapters.Csv,
  http_client: DistributedPerformanceAnalyzer.Infrastructure.Adapters.Http.HttpClient

if Mix.env() == :dev do
  config :git_hooks,
    auto_install: true,
    hooks: [
      pre_commit: [
        verbose: true,
        tasks: [
          {:file, "./hooks/mix_format"},
          {:mix_task, :format, ["--check-formatted", "--dry-run"]},
          {:mix_task, :test, ["--color", "--cover"]},
          {:mix_task, :credo,
           [
             "--all",
             "--sonarqube-base-folder",
             "./",
             "--sonarqube-file",
             "credo_sonarqube.json",
             "--mute-exit-status"
           ]},
          {:mix_task, :sobelow, ["--config"]}
        ]
      ]
    ]
end

import_config "#{Mix.env()}.exs"
