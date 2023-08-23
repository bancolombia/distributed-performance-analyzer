defmodule DistributedPerformanceAnalyzer.Domain.UseCase.Config.ConfigUseCase do
  alias DistributedPerformanceAnalyzer.Utils.DataTypeUtils
  alias DistributedPerformanceAnalyzer.Domain.Model.{Request, ExecutionModel}

  require Logger

  def parse_config_file(application_envs) do
    url = application_envs[:url]
    distributed = application_envs[:distributed]
    execution = application_envs[:execution]
    request = application_envs[:request]
    jmeter_report = application_envs[:jmeter_report]

    Logger.info("JMeter Report enabled: #{jmeter_report}")

    %{
      host: host,
      path: path,
      scheme: scheme,
      port: port,
      query: query
    } = DataTypeUtils.parse(url)

    connection_conf = {scheme, host, port}

    {:ok, request_conf} =
      request
      |> Map.put(:path, DataTypeUtils.path(path, query))
      |> Map.put(:url, url)
      |> Request.new()

    {:ok, execution_conf} =
      execution
      |> Map.put(:request, request_conf)
      |> ExecutionModel.new()

    {:ok,
     %{
       distributed: distributed,
       connection_conf: connection_conf,
       execution_conf: execution_conf
     }}
  end
end
