use Mix.Config

config :perf_analizer,
       host: {:http, "127.0.0.1", 8080},
       request: %{method: "GET", path: "/wait/200", headers: [], body: ""},
       execution: %{steps: 4, increment: 10, duration: 5000, constant_load: true},
       distributed: :none