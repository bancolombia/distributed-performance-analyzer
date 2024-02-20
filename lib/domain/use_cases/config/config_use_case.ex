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
    conf |> Enum.each(&:ets.insert(__MODULE__, &1))
    {:ok, nil}
  end

  def get(config_key) do
    [{^config_key, conf}] = :ets.lookup(__MODULE__, config_key)
    conf
  end

  def get(config_key, default), do: get(config_key) || default

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
    strategies = parse_config_to_model(env[:strategies], &Strategy.new/1)

    datasets =
      if env[:datasets], do: parse_config_to_model(env[:datasets], &Dataset.new/1), else: nil

    scenarios =
      env[:scenarios]
      |> Enum.map(&create_scenario(&1, requests, strategies, datasets))

    %{scenarios: scenarios, datasets: datasets}
  end

  defp parse_v1_config(env) do
    url = env[:url]
    execution_map = env[:execution]
    request_map = env[:request]

    {:ok, request} = request_map |> Map.put(:url, url) |> Request.new()
    {:ok, strategy} = Strategy.new(execution_map)

    dataset_value = Map.get(execution_map, :dataset)
    dataset_path = if dataset_value == :none, do: nil, else: dataset_value
    dataset_name = (dataset_path && "default") || nil

    datasets =
      if dataset_path do
        case execution_map |> Map.put(:path, dataset_path) |> Dataset.new() do
          {:ok, dataset} ->
            [default: dataset]

          {:error, reason} ->
            raise(ConfigError, message: "Error with dataset, " <> inspect(reason))
        end
      end

    scenarios =
      [default: %{request: "default", dataset: dataset_name, strategy: "default", depends: nil}]
      |> Enum.map(&create_scenario(&1, [default: request], [default: strategy], datasets))

    %{scenarios: scenarios, datasets: datasets}
  end

  defp identify_config_file_version(env) do
    if env[:requests] &&
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

  defp create_scenario({scenario_name, scenario_map}, requests, strategies, datasets) do
    %{request: request, strategy: strategy} = scenario_map
    dataset_value = Map.get(scenario_map, :dataset)
    dataset_name = if dataset_value == :none, do: nil, else: dataset_value

    request_model = requests[String.to_atom(request)]
    strategy_model = strategies[String.to_atom(strategy)]

    dataset_model = if dataset_name, do: datasets[String.to_atom(dataset_name)]

    if request_model && strategy_model && (!dataset_name or is_map(dataset_model)) do
      {:ok, scenario} =
        scenario_map
        |> Map.put(:request, request_model)
        |> Map.put(:strategy, strategy_model)
        |> Map.put(:name, Atom.to_string(scenario_name))
        |> Map.put(:dataset_name, dataset_name)
        |> Scenario.new()

      scenario
    else
      raise(ConfigError,
        message: error_message(request_model, strategy_model, dataset_model, scenario_name)
      )
    end
  end

  defp error_message(request_model, strategy_model, dataset_model, key) do
    cond do
      !request_model -> "request on #{inspect(key)} scenario doesn't exists"
      !strategy_model -> "strategy on #{inspect(key)} scenario doesn't exists"
      !dataset_model -> "dataset on #{inspect(key)} scenario doesn't exists"
    end
  end
end
