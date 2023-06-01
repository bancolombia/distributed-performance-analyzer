import Config

config :distributed_performance_analyzer,
  url: "http://localhost:8080/wait/100",
  request: %{
    method: "GET",
    headers: [{"Content-Type", "application/json"}],
    body: ""
  },
  execution: %{
    steps: 5,
    increment: 1,
    duration: 5000,
    constant_load: false,
    dataset: :none,
    separator: ","
  },
  distributed: :none,
  jmeter_report: true

config :logger,
  level: :info
