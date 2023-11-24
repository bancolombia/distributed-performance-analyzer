defmodule DistributedPerformanceAnalyzer.Domain.UseCase.Execution.ExecutionUseCase do
  @moduledoc """
  Use case for execution that's responsible for ordering scenarios and executing them
  """

  use GenServer
  require Logger

  alias DistributedPerformanceAnalyzer.Domain.Model.Scenario

  alias DistributedPerformanceAnalyzer.Domain.UseCase.{
    Config.ConfigUseCase,
    Step.StepUseCase,
    Execution.ExecutionSupervisor
  }

  defstruct [:waiting, :ready, :in_progress, :done]

  def start_link(_) do
    Logger.debug("Starting executor server...")
    GenServer.start_link(__MODULE__, ConfigUseCase.get(:scenarios), name: __MODULE__)
  end

  def launch_execution() do
    GenServer.call(__MODULE__, :launch_execution)
  end

  def continue_execution(done_scenario) do
    GenServer.call(__MODULE__, {:continue_execution, done_scenario})
  end

  @impl true
  def init(scenarios) do
    IO.puts("Initializing Distributed Performance Analyzer...")
    Supervisor.start_link([ExecutionSupervisor], strategy: :one_for_one)
    state = order_scenarios(scenarios)

    case state.ready do
      [] -> {:error, :no_scenarios_to_execute_at_first}
      _ -> {:ok, state}
    end
  end

  @impl true
  def handle_call(:launch_execution, _from, state) do
    state.ready |> start_scenarios()
    {:reply, :ok, %{state | in_progress: state.in_progress ++ state.ready, ready: []}}
  end

  @impl true
  def handle_call({:continue_execution, done_scenario}, _from, state) do
    new_state = order_scenarios(state, done_scenario)

    {ready_scenarios, waiting} =
      new_state.waiting

    start_scenarios(ready_scenarios)

    {:reply, :ok,
     %{new_state | waiting: waiting, in_progress: new_state.in_progress ++ ready_scenarios}}
  end

  defp order_scenarios(scenarios) when is_list(scenarios) do
    {ready, waiting} = scenarios |> Enum.split_with(&(&1.depends == :none || &1.depends == []))

    %{waiting: waiting, ready: ready, in_progress: [], done: []}
  end

  defp order_scenarios(state, done_scenario_name) when is_map(state) do
    done_scenario = state.in_progress |> Enum.find(&(&1.name == done_scenario_name))

    {ready, waiting} =
      state.waiting
      |> Enum.map(fn scenario ->
        %{scenario | depends: scenario.depends |> Enum.filter(&(&1 != done_scenario_name))}
      end)
      |> Enum.split_with(&Enum.empty?(&1.depends))

    %{
      state
      | ready: state.ready ++ ready,
        waiting: waiting,
        in_progress: state.in_progress -- [done_scenario],
        done: state.done ++ [done_scenario]
    }
  end

  defp start_scenarios([]), do: {:error, :no_scenarios_to_execute}

  defp start_scenarios(scenarios) when is_list(scenarios) do
    scenarios
    |> Enum.map(&Task.async(fn -> ExecutionSupervisor.start_scenario(&1) end))
    |> Task.await_many()
  end
end
