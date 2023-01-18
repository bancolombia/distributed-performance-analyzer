import Config

config :distributed_performance_analyzer, timezone: "America/Bogota"

config :distributed_performance_analyzer,
       http_port: 8083,
       enable_server: true,
       secret_name: "",
       region: "",
       version: "0.0.1",
       in_test: false,
       custom_metrics_prefix_name: "distributed_performance_analyzer_local"

config :logger,
       level: :debug
