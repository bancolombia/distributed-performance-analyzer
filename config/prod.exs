use Mix.Config


config :perf_analizer,
       url: "http://127.0.0.1:8080/wait/1",
       request: %{method: "POST", headers: [{"Content-Type", "application/json"}], body: "{\"key\": \"example\"}"},
       execution: %{steps: 5, increment: 370, duration: 7000, constant_load: true},
       distributed: :none


config :logger,
       level: :info
