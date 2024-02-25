defmodule DistributedPerformanceAnalyzer.Domain.UseCase.Scenario.ScenarioSupervisor do
  @moduledoc """
  Scenario supervisor for managing execution of steps
  """

  use DynamicSupervisor
  require Logger

  alias DistributedPerformanceAnalyzer.Domain.Model.{Config.Step, Scenario}
  alias DistributedPerformanceAnalyzer.Domain.UseCase.Step.StepUseCase

  def start_link(scenario_name) do
    Logger.debug("Starting supervisor for scenario #{scenario_name}...")
    DynamicSupervisor.start_link(name: get_supervisor_name(scenario_name), strategy: :one_for_one)
  end

  @impl true
  def init(_), do: {:ok, nil}

  def child_spec(scenario_name) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [scenario_name]},
      type: :supervisor
    }
  end

  def start_step(%Step{scenario: %Scenario{name: name}} = step) do
    case start_child(get_supervisor_name(name), step) do
      {:ok, pid} -> pid
      {:error, {:already_started, pid}} -> pid
    end
  end

  def stop_step(%Scenario{name: name}, step_pid),
    do: stop_child(get_supervisor_name(name), step_pid)

  defp start_child(scenario_name, step),
    do: DynamicSupervisor.start_child(scenario_name, {StepUseCase, step})

  defp stop_child(scenario_name, step_pid),
    do: DynamicSupervisor.terminate_child(scenario_name, step_pid)

  defp get_supervisor_name(scenario_name),
    do: String.to_atom("#{scenario_name}_scenario_supervisor")
end
