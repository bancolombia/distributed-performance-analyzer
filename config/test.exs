import Config

config :distributed_performance_analyzer,
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
    steps: 2,
    increment: 1,
    duration: 5000,
    constant_load: false,
    dataset: :none,
    separator: ","
  },
  distributed: :none,
  jmeter_report: true

config :logger,
  level: :debug
