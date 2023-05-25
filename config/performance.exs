import Config

config :distributed_performance_analyzer,
  url: "http://localhost:8080/wait/100",
  request: %{
    method: "POST",
    headers: [
      {"message-id", ~s|e0420cc4-2f0a-4816-9208-49864b5c9e99|},
      {"session-tracker", ~s|e0420cc4-2f0a-4816-9208-49864b5c9e99|},
      {"channel", ~s|APP|},
      {"request-timestamp", ~s|2017-02-14 19:30:59:000|},
      {"ip", ~s|10.18.140.5|},
      {"user-agent",
       ~s|Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/93.0.4577.82 Safari/537.36|},
      {"device-id", ~s|e0420cc4-2f0a-4816-9208-49864b5c9e99|},
      {"app-version", ~s|1|},
      {"platform-type", ~s|web|},
      {"Content-Type", ~s|application/json|}
    ],
    body: fn item ->
      ~s|{"account": {"type": "S","number": "#{item.v_int_cuenta}"},"customer": {"type": "#{item.v_str_documenttype}","number": "#{item.v_int_documentid}"}}|
    end
  },
  execution: %{
    steps: 5,
    increment: 1,
    duration: 120_000,
    constant_load: false,
    dataset: "/mnt/c/Users/lcdelgad/Downloads/DT_Intervencion_Transferencia.csv",
    separator: ","
  },
  distributed: :none,
  jmeter_report: true

config :logger,
  level: :info
