import Config

config :distributed_performance_analyzer, timezone: "America/Bogota"

config :distributed_performance_analyzer,
  http_port: 8083,
  enable_server: true,
  secret_name: "",
  region: "",
  version: "0.0.1",
  in_test: false,
  custom_metrics_prefix_name: "distributed_performance_analyzer_local"

config :perf_analyzer,
  url: "http://127.0.0.1:8080/wait/1000",
  request: %{
    method: "GET",
    headers: [{"Content-Type", "application/json"}],
    body: ""
  },
  execution: %{
    steps: 5,
    increment: 1,
    duration: 7000,
    constant_load: true,
    dataset: :none,
    separator: ","
  },
  distributed: :none,
  jmeter_report: true

config :logger,
  level: :debug

config :app,
  file_system_behaviour: DistributedPerformanceAnalyzer.Domain.Behaviours.FileSystemBehaviour
