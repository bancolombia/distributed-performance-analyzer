defmodule DistributedPerformanceAnalyzer.Domain.UseCase.Config.ConfigUseCase do
  alias DistributedPerformanceAnalyzer.Application
  alias DistributedPerformanceAnalyzer.Utils.DataTypeUtils
  alias DistributedPerformanceAnalyzer.Domain.Model.{Request, ExecutionModel}

  require Logger

  def parse_config_file(application_envs) do
    Logger.info("JMeter Report enabled: #{application_envs[:jmeter_report]}")

    url = application_envs[:url]
    distributed = application_envs[:distributed]

    %{
      host: host,
      path: path,
      scheme: scheme,
      port: port,
      query: query
    } = DataTypeUtils.parse(url)

    connection_conf = {scheme, host, port}

    {:ok, request} =
      application_envs[:request]
      |> Map.put(:path, DataTypeUtils.path(path, query))
      |> Map.put(:url, url)
      |> Request.new()

    {:ok, execution_conf} =
      application_envs[:execution]
      |> Map.put(:request, request)
      |> ExecutionModel.new()

    {:ok,
     %{
       distributed: distributed,
       connection_conf: connection_conf,
       execution_conf: execution_conf
     }}
  end

  def load_dataset(%{dataset: path, separator: separator}) when is_binary(path) do
    with {:ok, dataset} <- DatasetUseCase.parse(path, separator) do
      dataset
    else
      err -> Application.stop(err)
    end
  end

  def load_dataset(%{dataset: dataset}), do: dataset
end
