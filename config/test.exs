use Mix.Config

config :perf_analizer,
       host: {:https, "test.api.upet.co", 443},
       request: %{method: "GET", path: "/", headers: [], body: ""},
       execution: %{steps: 1, increment: 1, duration: 10}