import Config

config :distributed_performance_analyzer,
  url: "http://localhost:8080/wait/100",
  request: %{
    url: "http://localhost:8080/wait/100",
    method: "GET",
    headers: [{"Content-Type", "application/json"}],
    body: "Test 0"
  },
  requests: [
    %{
      url: "http://localhost:8080/wait/100",
      method: "GET",
      headers: [{"Content-Type", "application/json"}],
      body: "Test 1"
    },
    %{
      url: "http://localhost:8080/wait/100",
      method: "GET",
      headers: [{"Content-Type", "application/json"}],
      body: "Test 2"
    }
  ],
  execution: %{
    steps: 5,
    increment: 1,
    duration: 3000,
    constant_load: false,
    dataset: :none,
    separator: ",",
    mode: :sequential
  },
  distributed: :none,
  jmeter_report: true

config :logger,
  level: :info
