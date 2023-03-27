import Config

config :perf_analyzer,
  url: "http://httpbin.org/get",
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
    duration: 5000,
    constant_load: false,
    dataset: :none,
    separator: ","
  },
  distributed: :none,
  jmeter_report: true

config :logger,
  level: :info

config :app,
  file_system_behaviour: DistributedPerformanceAnalyzer.Domain.Behaviours.FileSystemBehaviour
