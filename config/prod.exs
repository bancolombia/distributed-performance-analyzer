import Config

config :distributed_performance_analyzer,
  url: "http://localhost:8080/post",
  request: %{
    method: "POST",
    headers: [{"Content-Type", "application/json"}],
    body: ~s/{"key": "example"}/
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
  level: :info
