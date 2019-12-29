use Mix.Config

config :perf_analizer,
       host: {:http, "127.0.0.1", 8080},
       request: %{method: "GET", path: "/wait/200", headers: [], body: ""},
       execution: %{steps: 5, increment: 5, duration: 5000},
       distributed: :slave