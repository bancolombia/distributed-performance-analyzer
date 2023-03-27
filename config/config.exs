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
  file_system_behaviour: DistributedPerformanceAnalyzer.Domain.Behaviours.FileSystemBehaviour,
  dataset_behaviour: DistributedPerformanceAnalyzer.Domain.Behaviours.DataSetBehaviour

import_config "#{Mix.env()}.exs"
