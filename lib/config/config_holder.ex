defmodule DistributedPerformanceAnalyzer.Config.ConfigHolder do
  use GenServer

  @dataset_behaviour Application.compile_env(
                       :distributed_performance_analyzer,
                       :dataset_behaviour
                     )

  @moduledoc """
  Provides Behaviours for handle app-configs
  """

  def start_link(conf) do
    GenServer.start_link(__MODULE__, conf, name: __MODULE__)
  end

  def init(conf) do
    conf_dataset = Map.put(conf, :dataset, load_dataset(conf))
    :ets.new(__MODULE__, [:named_table])
    :ets.insert(__MODULE__, {:conf, conf_dataset})
    {:ok, nil}
  end

  def get() do
    [{:conf, conf}] = :ets.lookup(__MODULE__, :conf)
    conf
  end

  defp load_dataset(%{dataset: path, separator: separator}) when is_binary(path) do
    {:ok, dataset} = @dataset_behaviour.parse_csv(path, separator)
    dataset
  end

  defp load_dataset(%{dataset: dataset}), do: dataset
end
