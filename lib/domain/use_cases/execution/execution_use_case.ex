defmodule DistributedPerformanceAnalyzer.Domain.UseCase.Execution.ExecutionUseCase do
  @moduledoc """
  Use case for execution that's responsible for ordering scenarios and executing them
  """

  use GenServer
  require Logger

  alias DistributedPerformanceAnalyzer.Domain.UseCase.{
    Config.ConfigUseCase,
    Execution.ExecutionSupervisor
  }

  defstruct [:waiting, :ready, :in_progress, :done]

  def start_link(_) do
    Logger.debug("Starting executor server...")
    GenServer.start_link(__MODULE__, ConfigUseCase.get(:scenarios), name: __MODULE__)
  end

  @impl true
  def init(scenarios) do
    Logger.info("Initializing Distributed Performance Analyzer...")
    Supervisor.start_link([ExecutionSupervisor], strategy: :one_for_one)
    state = order_scenarios(scenarios)

    case state.ready do
      [] -> {:error, :no_scenarios_to_execute_at_first}
      _ -> {:ok, state, {:continue, :launch_execution}}
    end
  end

  @impl true
  def handle_continue(:launch_execution, state) do
    state.ready |> start_scenarios()

    # TODO: Improve app stop
    #    Process.monitor(Process.whereis(MetricsAnalyzerUseCase))
    #
    #    receive do
    #      {:DOWN, _ref, :process, _pid, :normal} ->
    #        Application.stop()
    #    end

    {:noreply, %{state | in_progress: state.in_progress ++ state.ready, ready: []}}
  end

  def continue_execution(done_scenario),
    do: GenServer.call(__MODULE__, {:continue_execution, done_scenario})

  defp order_scenarios(scenarios) when is_list(scenarios) do
    {ready, waiting} = scenarios |> Enum.split_with(&(&1.depends == nil || &1.depends == []))

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

  defp start_scenarios([]), do: Logger.error("No scenarios to execute")

  defp start_scenarios(scenarios) when is_list(scenarios) do
    scenarios
    |> Enum.map(&Task.async(fn -> ExecutionSupervisor.start_scenario(&1) end))
    |> Task.await_many()
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
end
