defmodule DistributedPerformanceAnalyzer.Config.ConfigHolder do
  use GenServer
  require Logger

  @moduledoc """
  Provides Behaviours for handle app-configs
  """

  def start_link(conf) do
    Logger.debug("Starting config server...")
    GenServer.start_link(__MODULE__, conf, name: __MODULE__)
  end

  def init(conf) do
    :ets.new(__MODULE__, [:named_table])
    :ets.insert(__MODULE__, {:conf, conf})
    {:ok, nil}
  end

  def get() do
    [{:conf, conf}] = :ets.lookup(__MODULE__, :conf)
    conf
  end
end
