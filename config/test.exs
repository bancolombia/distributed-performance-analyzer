import Config

config :distributed_performance_analyzer, timezone: "America/Bogota"

config :distributed_performance_analyzer,
  http_port: 8083,
  enable_server: true,
  secret_name: "",
  region: "",
  version: "0.0.1",
  in_test: true,
  custom_metrics_prefix_name: "distributed_performance_analyzer_local"

config :perf_analyzer,
  url: "http://localhost:8080/post",
  request: %{
    method: "POST",
    headers: [
      {"Content-Type", "application/json"}
    ],
    body: ~s/{
        "data": {
            "customer": {
                "identification": {
                    "type": "{type}",
                    "number": "{number}"
                }
            },
            "pagination": {
                "size": #{Enum.random(0..10)},
                "key": 1
            }
        }
    }/
  },
  execution: %{
    steps: 10,
    increment: 1,
    duration: 10000,
    constant_load: false,
    dataset: :none,
    separator: ","
  },
  distributed: :none,
  jmeter_report: true

config :logger,
  level: :debug

config :app,
  file_system_behaviour: DistributedPerformanceAnalyzer.Domain.Behaviours.FileSystemBehaviour
  dataset_behaviour: DistributedPerformanceAnalyzer.Domain.Behaviours.DataSetBehaviour
