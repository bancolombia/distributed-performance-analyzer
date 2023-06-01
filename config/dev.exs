import Config

config :distributed_performance_analyzer,
  url: "http://localhost:8080/wait/100",
  request: %{
    method: "GET",
    headers: [{"Content-Type", "application/json"}],
    body: fn _item ->
      ~s/'{"data":  #{Enum.random(1..10)},"key": 1}}}'/
    end
  },
  execution: %{
    steps: 5,
    increment: 1,
    duration: 3000,
    constant_load: true,
    dataset: :none,
    separator: ","
  },
  distributed: :none,
  jmeter_report: true

config :logger,
  level: :info

config :git_hooks,
  auto_install: true,
  hooks: [
    pre_commit: [
      verbose: true,
      tasks: [
        {:file, "./hooks/mix_format"},
        {:mix_task, :format, ["--check-formatted", "--dry-run"]},
        {:mix_task, :test, ["--color", "--cover"]},
        {:mix_task, :credo,
         [
           "--sonarqube-base-folder",
           "./",
           "--sonarqube-file",
           "credo_sonarqube.json",
           "--mute-exit-status"
         ]},
        {:mix_task, :sobelow}
      ]
    ]
  ]
