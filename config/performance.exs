import Config

config :distributed_performance_analyzer,
  requests: [
    wait: %{
      url: "http://localhost:8080/wait/100",
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
    },
    data2: %{
      path: "./datasets/data_performance.csv",
      separator: ",",
      ordered: false
    }
  ],
  strategies: [
    short_constant: %{
      steps: 10,
      initial: 5,
      increment: 1,
      duration: 2000,
      constant_load: true
    },
    large_increment: %{
      steps: 10,
      increment: 10,
      duration: 3000,
      constant_load: false
    }
  ],
  scenarios: [
    load: %{
      request: "wait",
      dataset: "data1",
      strategy: "short_constant",
      depends: :none
    },
    load2: %{
      request: "real_time",
      dataset: "data2",
      strategy: "large_increment",
      depends: "load"
    },
    load3: %{
      request: "real_time",
      dataset: "data2",
      strategy: "large_increment",
      depends: :none
    }
  ],
  distributed: :none,
  jmeter_report: true

config :logger,
  level: :debug
