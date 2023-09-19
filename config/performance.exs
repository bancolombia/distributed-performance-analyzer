import Config

config :distributed_performance_analyzer,
  requests: [
    wait: %{
      url: "http://localhost:8080/wait/10",
      method: "GET",
      headers: ["Content-Type": "application/json"],
      body: ""
    },
    real_time: %{
      url: "http://localhost:8080/wait/0",
      method: "POST",
      headers: ["Content-Type": "application/json"],
      body: ""
    }
  ],
  datasets: [
    data1: %{
      path: "./datasets/data_performance.csv",
      separator: ",",
      ordered: false
    }
  ],
  strategies: [
    short_constant: %{
      steps: 5,
      increment: 100,
      duration: 1000,
      constant_load: true
    }
  ],
  scenarios: [
    load: %{
      request: "wait",
      dataset: "data1",
      strategy: "short_constant",
      depends: :none
    }
  ],
  distributed: :none,
  jmeter_report: true

config :logger,
  level: :info
