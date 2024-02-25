defmodule DistributedPerformanceAnalyzer.Domain.UseCase.Scenario.ScenarioUseCase do
  @moduledoc """
  Scenario use case
  """

  use GenServer, restart: :temporary
  require Logger

  alias DistributedPerformanceAnalyzer.Domain.Model.{Scenario, Config.Strategy, Config.Step}
  alias DistributedPerformanceAnalyzer.Domain.UseCase.Scenario.ScenarioSupervisor

  defmodule State, do: defstruct([:scenario, :step_number, :running_step])

  def start_link(%Scenario{} = scenario) do
    Logger.info("Starting scenario #{scenario.name}...")
    GenServer.start_link(__MODULE__, scenario, name: get_process_name(scenario.name))
  end

  @impl true
  def init(%Scenario{name: name} = scenario) do
    Supervisor.start_link([{ScenarioSupervisor, name}], strategy: :one_for_one)

    {:ok, %State{scenario: scenario, step_number: nil, running_step: nil},
     {:continue, :start_scenario}}
  end

  @impl true
  def handle_continue(:start_scenario, %State{} = state) do
    resume_scenario(0)
    {:noreply, %{state | step_number: 1}}
  end

  @impl true
  def handle_info(
        :resume_scenario,
        %State{scenario: scenario, step_number: step_number, running_step: running_step} = state
      ) do
    %Strategy{steps: steps, duration: duration} = scenario.strategy
    if running_step, do: stop_step(scenario, running_step)

    if step_number <= steps do
      start_step(state)
      resume_scenario(duration)
      {:noreply, %{state | step_number: step_number + 1}}
    else
      Logger.info("Scenario #{scenario.name} completed")
      {:stop, :normal, state}
    end
  end

  defp start_step(%{scenario: scenario, step_number: step_number}) do
    {:ok, step} = Step.new(%{scenario: scenario, number: step_number})
    ScenarioSupervisor.start_step(step)
  end

  defp stop_step(%Scenario{} = scenario, running_step),
    do: ScenarioSupervisor.stop_step(scenario, running_step)

  defp resume_scenario(duration),
    do: Process.send_after(self(), :resume_scenario, duration)

  defp get_process_name(scenario_name), do: String.to_atom("#{scenario_name}_scenario")
end
