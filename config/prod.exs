use Mix.Config

config :perf_analizer,
       host: {:http, "127.0.0.1", 3000},
       request: %{method: "GET", path: "/api/admin/apps", headers: [], body: ""},
       execution: %{steps: 3, increment: 300, duration: 5000},
       distributed: :slave