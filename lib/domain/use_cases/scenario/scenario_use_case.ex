defmodule DistributedPerformanceAnalyzer.Domain.UseCase.Scenario.ScenarioUseCase do
  @moduledoc """
  Scenario use case
  """

  use GenServer, restart: :temporary
  require Logger

  alias DistributedPerformanceAnalyzer.Domain.Model.{Scenario, Config.Step}
  alias DistributedPerformanceAnalyzer.Domain.UseCase.Scenario.ScenarioSupervisor

  defstruct [:scenario, :step_number]

  def start_link(scenario) do
    Logger.info("Starting scenario #{scenario.name}...")
    GenServer.start_link(__MODULE__, scenario, name: get_process_name(scenario.name))
  end

  @impl true
  def init(scenario) do
    Supervisor.start_link([{ScenarioSupervisor, scenario.name}], strategy: :one_for_one)
    {:ok, %{scenario: scenario, step_number: 1}, {:continue, :start_scenario}}
  end

  @impl true
  def handle_continue(:start_scenario, state) do
    start_scenario(state)
    {:noreply, state}
  end

  defp start_scenario(%{scenario: scenario, step_number: step_number}) do
    {:ok, step} = Step.new(%{scenario: scenario, number: step_number})
    ScenarioSupervisor.start_step(step)
  end

  defp get_process_name(scenario_name), do: String.to_atom("#{scenario_name}_scenario")
end
