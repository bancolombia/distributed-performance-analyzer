defmodule DistributedPerformanceAnalyzer.Domain.UseCase.Config.ConfigUseCase do
  @moduledoc """
  Use case for global config
  """

  alias DistributedPerformanceAnalyzer.Domain.Model.{Scenario}
  alias DistributedPerformanceAnalyzer.Domain.Model.Config.{Dataset, Request, Strategy}
  alias DistributedPerformanceAnalyzer.Domain.Model.Errors.ConfigError

  use GenServer
  require Logger

  def start_link(application_envs) do
    Logger.debug("Starting config server...")
    GenServer.start_link(__MODULE__, load_config(application_envs), name: __MODULE__)
  end

  def init(conf) do
    :ets.new(__MODULE__, [:named_table])
    conf |> Enum.map(&:ets.insert(__MODULE__, &1))
    {:ok, nil}
  end

  def get(config_key) do
    [{^config_key, conf}] = :ets.lookup(__MODULE__, config_key)
    conf
  end

  def load_config(application_envs) do
    distributed = application_envs[:distributed]
    jmeter_report = application_envs[:jmeter_report]

    Logger.info("JMeter Report enabled: #{jmeter_report}")

    case identify_config_file_version(application_envs) do
      2 -> parse_v2_config(application_envs)
      1 -> parse_v1_config(application_envs)
    end
    |> Map.put(:distributed, distributed)
    |> Map.put(:jmeter_report, jmeter_report)
  end

  defp parse_v2_config(env) do
    requests = parse_config_to_model(env[:requests], &Request.new/1)
    datasets = parse_config_to_model(env[:datasets], &Dataset.new/1)
    strategies = parse_config_to_model(env[:strategies], &Strategy.new/1)

    scenarios =
      env[:scenarios]
      |> Enum.map(&create_scenario(&1, requests, strategies, datasets))

    %{scenarios: scenarios, datasets: datasets}
  end

  defp parse_v1_config(env) do
    url = env[:url]
    %{dataset: dataset_path} = execution = env[:execution]

    {:ok, request} =
      env[:request]
      |> Map.put(:url, url)
      |> Request.new()

    {:ok, strategy} = Strategy.new(execution)

    {:ok, dataset} =
      execution
      |> Map.put(:path, dataset_path)
      |> Dataset.new()

    datasets = [default: dataset]

    scenarios =
      [default: %{request: "default", dataset: "default", strategy: "default", depends: :none}]
      |> Enum.map(&create_scenario(&1, [default: request], [default: strategy], datasets))

    %{scenarios: scenarios, datasets: datasets}
  end

  defp identify_config_file_version(env) do
    if env[:requests] &&
         env[:datasets] &&
         env[:strategies] &&
         env[:scenarios],
       do: 2,
       else: 1
  end

  defp parse_config_to_model(items, constructor)
       when is_list(items) and is_function(constructor) do
    Enum.map(items, fn {key, item} ->
      {:ok, entity} = constructor.(item)
      {key, entity}
    end)
  end

  defp create_scenario({key, value}, requests, strategies, datasets) do
    %{request: request, strategy: strategy, dataset: dataset} = value

    request_model = requests[String.to_atom(request)]
    strategy_model = strategies[String.to_atom(strategy)]
    dataset_model = datasets[String.to_atom(dataset)]

    if request_model && strategy_model && dataset_model do
      {:ok, scenario} =
        %{value | request: request_model, strategy: strategy_model}
        |> Map.put(:dataset_name, dataset)
        |> Scenario.new()

      {key, scenario}
    else
      unless request_model,
        do:
          raise(ConfigError,
            message: "request #{inspect(request)} on #{inspect(key)} scenario doesn't exists"
          )

      unless strategy_model,
        do:
          raise(ConfigError,
            message: "strategy #{inspect(strategy)} on #{inspect(key)} scenario doesn't exists"
          )

      unless dataset_model,
        do:
          raise(ConfigError,
            message: "dataset #{inspect(dataset)} on #{inspect(key)} scenario doesn't exists"
          )
    end
  end
end
