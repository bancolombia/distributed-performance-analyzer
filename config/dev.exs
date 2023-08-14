import Config

config :distributed_performance_analyzer,
  url: "http://localhost:8080",
  requests: [
    %{
      url: "http://localhost:8080/wait/100",
      method: "GET",
      headers: [{"Content-Type", "application/json"}],
      body: fn _item ->
        ~s/'{"data":  #{Enum.random(1..10)},"key": 1}}}'/
      end
    }
  ],
  execution: %{
    steps: 5,
    increment: 1,
    duration: 3000,
    constant_load: true,
    dataset: :none,
    separator: ",",
    mode: :normal
  },
  distributed: :none,
  jmeter_report: true

config :logger,
  level: :info
