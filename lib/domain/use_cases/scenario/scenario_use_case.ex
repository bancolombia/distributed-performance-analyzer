defmodule DistributedPerformanceAnalyzer.Domain.UseCase.Scenario.ScenarioUseCase do
  @moduledoc """
  Scenario use case
  """

  use GenServer, restart: :temporary
  require Logger

  alias DistributedPerformanceAnalyzer.Domain.Model.Scenario

  def start_link(%Scenario{} = scenario) do
    Logger.info("Starting scenario #{scenario.name}...")
    GenServer.start_link(__MODULE__, scenario, name: __MODULE__)
  end

  @impl true
  def init(scenario) do
    {:ok, nil}
  end

  defp execute_step(%Scenario{} = scenario, step_number) when step_number > 0 do
  end

  defp execute_step(_, 0), do: :ok
end
