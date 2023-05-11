import Config

config :distributed_performance_analyzer,
  url: "http://127.0.0.1:8080/wait/1000",
  request: %{
    method: "GET",
    headers: [{"Content-Type", "application/json"}],
    body: fn _item ->
      ~s/'{"data":  #{Enum.random(1..10)},"key": 1}}}'/
    end
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
