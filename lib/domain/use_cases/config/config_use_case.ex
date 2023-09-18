defmodule DistributedPerformanceAnalyzer.Domain.UseCase.Config.ConfigUseCase do
  alias DistributedPerformanceAnalyzer.Utils.DataTypeUtils
  alias DistributedPerformanceAnalyzer.Domain.Model.{Request, ExecutionModel}

  require Logger

  def parse_config_file(application_envs) do
    distributed = application_envs[:distributed]
    jmeter_report = application_envs[:jmeter_report]

    Logger.info("JMeter Report enabled: #{jmeter_report}")

    case identify_config_file_version(application_envs) do
      2 ->
        requests = application_envs[:requests]
        datasets = application_envs[:datasets]
        strategies = application_envs[:strategies]
        scenarios = application_envs[:scenarios]

      1 ->
        url = application_envs[:url]
        execution = application_envs[:execution]
        request = application_envs[:request]

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

  defp identify_config_file_version(env) do
    if env[:requests] &&
         env[:datasets] &&
         env[:strategies] &&
         env[:scenarios],
       do: 2,
       else: 1
  end
end
