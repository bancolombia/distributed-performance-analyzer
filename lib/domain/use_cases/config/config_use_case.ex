defmodule DistributedPerformanceAnalyzer.Domain.UseCase.Config.ConfigUseCase do
  alias DistributedPerformanceAnalyzer.Utils.ConfigParser
  alias DistributedPerformanceAnalyzer.Domain.Model.{Request, ExecutionModel}

  require Logger

  def parse_config_file(application_envs) do
    Logger.info("JMeter Report enabled: #{application_envs[:jmeter_report]}")

    url = application_envs[:url]
    distributed = application_envs[:distributed]

    %{
      host: host,
      scheme: scheme,
      port: port
    } = ConfigParser.parse(url)

    connection_conf = {scheme, host, port}

    requests = ConfigParser.parse_requests(application_envs[:requests], url)
    request = ConfigParser.parse_requests(application_envs[:request], url)

    requests =
      (request ++ requests)
      |> Enum.map(&Request.new/1)
      |> Enum.map(fn {:ok, result} -> result end)

    {:ok, execution_conf} =
      application_envs[:execution]
      |> Map.put(:requests, requests)
      |> ExecutionModel.new()

    {:ok,
     %{
       distributed: distributed,
       connection_conf: connection_conf,
       execution_conf: execution_conf
     }}
  end
end
