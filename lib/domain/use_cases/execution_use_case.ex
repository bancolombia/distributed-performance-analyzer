defmodule DistributedPerformanceAnalyzer.Domain.UseCase.ExecutionUseCase do
  @moduledoc """
  Execution use case
  """
  alias DistributedPerformanceAnalyzer.Domain.Model.Config.Step

  alias DistributedPerformanceAnalyzer.Domain.UseCase.{
    LoadStepUseCase,
    MetricsAnalyzerUseCase,
    Config.ConfigUseCase,
    Step.StepUseCase
  }

  use GenServer
  require Logger

  defstruct [:request, :steps, :increment, :duration]

  def start_link(_) do
    Logger.debug("Starting executor server...")
    GenServer.start_link(__MODULE__, %{actual_step: -1, steps: 0}, name: __MODULE__)
  end

  def launch_execution() do
    GenServer.call(__MODULE__, :launch_execution)
  end

  @impl true
  def init(state) do
    IO.puts("Initializing Distributed Performance Analyzer...")
    #    TODO: do parallel
    scenario = ConfigUseCase.get(:scenarios) |> Enum.at(0) |> elem(1)
    {:ok, %{state | steps: scenario.strategy.steps}}
  end

  @impl true
  def handle_call(:launch_execution, _from, conf = %{actual_step: -1}) do
    GenServer.cast(self(), :continue_execution)
    {:reply, :ok, %{conf | actual_step: 1}}
  end

  @impl true
  def handle_call(:launch_execution, _from, conf) do
    IO.warn("Performance test already running")
    IO.inspect(conf)
    {:reply, :error, conf}
  end

  @impl true
  def handle_cast(:continue_execution, state = %{actual_step: actual_step, steps: steps})
      when actual_step <= steps do
    #    TODO: parallel
    scenario = ConfigUseCase.get(:scenarios) |> Enum.at(0) |> elem(1)

    {:ok, step_conf} = Step.new(scenario: scenario, number: state.actual_step)
    start_step(step_conf)

    {:noreply, %{state | actual_step: state.actual_step + 1}}
  end

  @impl true
  def handle_cast(:continue_execution, state = %{actual_step: actual_step, steps: steps})
      when actual_step > steps do
    MetricsAnalyzerUseCase.compute_metrics()
    {:noreply, %{state | actual_step: -1}}
  end

  defp start_step(step_conf) do
    IO.puts(
      "Initiating #{StepUseCase.get_name(step_conf)}, with #{StepUseCase.get_concurrency(step_conf)} actors"
    )

    Task.start_link(fn ->
      LoadStepUseCase.start_step(step_conf)
      GenServer.cast(__MODULE__, :continue_execution)
    end)
  end
end
