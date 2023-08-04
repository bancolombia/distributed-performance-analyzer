defmodule DistributedPerformanceAnalyzer.Domain.UseCase.Config.ConfigUseCase do
  alias DistributedPerformanceAnalyzer.Application
  alias DistributedPerformanceAnalyzer.Utils.DataTypeUtils
  alias DistributedPerformanceAnalyzer.Domain.Model.{Request, ExecutionModel}
  alias DistributedPerformanceAnalyzer.Domain.UseCase.Dataset.DatasetUseCase

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
    dataset = load_dataset(execution)

    {:ok, request_conf} =
      request
      |> Map.put(:path, DataTypeUtils.path(path, query))
      |> Map.put(:url, url)
      |> Request.new()

    {:ok, execution_conf} =
      execution
      |> Map.put(:request, request_conf)
      |> Map.put(:dataset, dataset)
      |> ExecutionModel.new()

    {:ok,
     %{
       distributed: distributed,
       connection_conf: connection_conf,
       execution_conf: execution_conf
     }}
  end

  defp load_dataset(%{dataset: path, separator: separator}) when is_binary(path) do
    with {:ok, dataset} <- DatasetUseCase.parse(path, separator) do
      dataset
    else
      err -> Application.stop(err)
    end
  end

  defp load_dataset(%{dataset: dataset}), do: dataset
end
