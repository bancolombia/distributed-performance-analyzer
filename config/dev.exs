use Mix.Config

config :perf_analizer,
       host: {:http, "httpbin.org", 80},
       request: %{method: "GET", path: "/", headers: [], body: ""},
       execution: %{steps: 1, increment: 10, duration: 1000}