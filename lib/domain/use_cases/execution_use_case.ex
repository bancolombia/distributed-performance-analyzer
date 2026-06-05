defmodule DistributedPerformanceAnalyzer.Domain.UseCase.ExecutionUseCase do
  @moduledoc """
  Execution use case
  """
  alias DistributedPerformanceAnalyzer.Domain.Model.Step

  alias DistributedPerformanceAnalyzer.Domain.UseCase.{
    LoadStepUseCase,
    MetricsAnalyzerUseCase,
    Reports.ReportUseCase
  }

  alias DistributedPerformanceAnalyzer.Config.ConfigHolder
  alias DistributedPerformanceAnalyzer.Utils.DpaEvent
  use GenServer
  require Logger

  defstruct [:request, :steps, :increment, :duration]

  def start_link(_) do
    Logger.debug("Starting executor server...")

    GenServer.start_link(__MODULE__, %{actual_step: -1, steps: 0, resume_step: 1},
      name: __MODULE__
    )
  end

  def launch_execution() do
    GenServer.call(__MODULE__, :launch_execution)
  end

  @impl true
  def init(state) do
    IO.puts("Initializing Distributed Performance Analyzer...")
    %{steps: total_steps} = ConfigHolder.get()
    completed = ReportUseCase.count_completed_steps()

    resume_step =
      if completed > 0 and completed < total_steps do
        Logger.info(
          "Resume detected: #{completed}/#{total_steps} steps completed. " <>
            "Resuming from step #{completed + 1}."
        )

        DpaEvent.emit(%{
          type: "resume_detected",
          completed_steps: completed,
          resuming_from: completed + 1,
          total_steps: total_steps
        })

        Application.put_env(:distributed_performance_analyzer, :dpa_resume_step, completed)
        completed + 1
      else
        DpaEvent.rotate_log()
        ReportUseCase.init_report_files()

        DpaEvent.emit(%{type: "execution_start", total_steps: total_steps})

        Application.put_env(:distributed_performance_analyzer, :dpa_resume_step, 0)
        1
      end

    {:ok, %{state | steps: total_steps, resume_step: resume_step}}
  end

  @impl true
  def handle_call(:launch_execution, _from, conf = %{actual_step: -1, resume_step: resume_step}) do
    GenServer.cast(self(), :continue_execution)
    {:reply, :ok, %{conf | actual_step: resume_step}}
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

    Step.new(execution_model: execution_model, step_number: state.actual_step)
    |> start_step()

    {:noreply, %{state | actual_step: state.actual_step + 1}}
  end

  @impl true
  def handle_cast(:continue_execution, state = %{actual_step: actual_step, steps: steps})
      when actual_step > steps do
    MetricsAnalyzerUseCase.compute_metrics()
    {:noreply, %{state | actual_step: -1}}
  end

  defp start_step({:ok, step_conf}) do
    IO.puts("Initiating #{step_conf.name}, with #{step_conf.concurrency} actors")

    {:ok, pid} =
      Task.start(fn ->
        LoadStepUseCase.start_step(step_conf)
        GenServer.cast(__MODULE__, :continue_execution)
      end)

    Process.monitor(pid)
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, _pid, :normal}, state) do
    {:noreply, state}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, _pid, reason}, state) do
    Logger.error("Step task crashed: #{inspect(reason)}")

    DpaEvent.emit(%{
      type: "step_task_crashed",
      reason: inspect(reason),
      actual_step: state.actual_step
    })

    GenServer.cast(self(), :continue_execution)
    {:noreply, state}
  end
end
