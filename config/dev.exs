use Mix.Config

config :perf_analizer,
       host: {:http, "127.0.0.1", 3000},
       request: %{method: "GET", path: "/api/admin/apps/10000", headers: [], body: ""},
       execution: %{steps: 5, increment: 15, duration: 5000}