use Mix.Config

config :perf_analizer,
       host: {:https, "test.api.upet.co", 443},
       request: %{method: "GET", path: "/rest/appInfo/version", headers: [], body: ""},
       execution: %{steps: 15, increment: 10, duration: 500}