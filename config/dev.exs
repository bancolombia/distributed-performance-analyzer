import Config

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
  distributed: :none

config :logger,
  level: :info
