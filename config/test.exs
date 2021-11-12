use Mix.Config

config :perf_analyzer,
       url: "http://127.0.0.1:3000/",
       request: %{
         method: "GET",
         path: "/",
         headers: [],
         body: ""
       },
       execution: %{
         steps: 0,
         increment: 1,
         duration: 10
       },
       distributed: :none
