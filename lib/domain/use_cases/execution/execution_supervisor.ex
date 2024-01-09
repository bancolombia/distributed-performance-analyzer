defmodule DistributedPerformanceAnalyzer.Domain.UseCase.Execution.ExecutionSupervisor do
  @moduledoc """
  Execution supervisor for managing execution of scenarios
  """

  use DynamicSupervisor
  require Logger

  alias DistributedPerformanceAnalyzer.Domain.UseCase.Scenario.ScenarioUseCase

  def start_link() do
    Logger.debug("Starting execution supervisor...")
    DynamicSupervisor.start_link(name: __MODULE__, strategy: :one_for_one)
  end

  @impl true
  def init(_), do: {:ok, nil}

  def child_spec(_arg) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []},
      type: :supervisor
    }
  end

  def start_scenario(scenario) do
    case start_child(scenario) do
      {:ok, pid} -> pid
      {:error, {:already_started, pid}} -> pid
    end
  end

  defp start_child(scenario),
    do: DynamicSupervisor.start_child(__MODULE__, {ScenarioUseCase, scenario})
end
