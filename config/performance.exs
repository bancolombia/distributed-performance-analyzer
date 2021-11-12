import Config

config :perf_analyzer,
       url: "http://localhost:3000",
       request: %{
         method: "GET",
         headers: [{"Content-Type", "application/json"}],
         body: "{\"key\": \"example\"}"
       },
       execution: %{
         steps: 5,
         increment: 10,
         duration: 10000,
         constant_load: true
       },
       distributed: :master


config :logger,
       level: :info
