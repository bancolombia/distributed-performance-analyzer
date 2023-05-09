defmodule DistributedPerformanceAnalyzer.Domain.UseCase.ExecutionUseCase do
  @moduledoc """
  Execution use case
  """
  alias DistributedPerformanceAnalyzer.Domain.Model.StepModel
  alias DistributedPerformanceAnalyzer.Domain.UseCase.{LoadStepUseCase, MetricsAnalyzerUseCase}
  alias DistributedPerformanceAnalyzer.Config.ConfigHolder
  use GenServer

  defstruct [:request, :steps, :increment, :duration]

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{actual_step: -1, steps: 0}, name: __MODULE__)
  end

  def launch_execution() do
    GenServer.call(__MODULE__, :launch_execution)
  end

  @impl true
  def init(state) do
    IO.puts("Initializing Distributed Performance Analyzer...")
    %{steps: steps} = ConfigHolder.get()
    {:ok, %{state | steps: steps}}
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
    execution_model = ConfigHolder.get()

    StepModel.new(execution_model, state.actual_step)
    |> start_step()

    {:noreply, %{state | actual_step: state.actual_step + 1}}
  end

  @impl true
  def handle_cast(:continue_execution, state = %{actual_step: actual_step, steps: steps})
      when actual_step > steps do
    MetricsAnalyzerUseCase.compute_metrics()
    {:noreply, %{state | actual_step: -1}}
  end

  defp start_step(step_conf) do
    IO.puts("Initiating #{step_conf.name}, with #{step_conf.concurrency} actors")

    Task.start_link(fn ->
      LoadStepUseCase.start_step(step_conf)
      GenServer.cast(__MODULE__, :continue_execution)
    end)
  end
end
