defmodule DistributedPerformanceAnalyzer.Domain.UseCase.MetricsCollectorUseCase do
  @moduledoc """
  Use case metrics collector.
  The metrics collector model module is called.

  The data executed by each step is captured and sent to the partialResult module,
  the result row of this step is also printed.
  """
  # alias DistributedPerformanceAnalyzer.Domain.Model.MetricsCollector
  # alias DistributedPerformanceAnalyzer.Domain.Model.RequestResult
  alias DistributedPerformanceAnalyzer.Domain.UseCase.PartialResultUseCase
  alias DistributedPerformanceAnalyzer.Utils.Statistics
  alias DistributedPerformanceAnalyzer.Domain.UseCase.Reports.ReportUseCase

  use GenServer

  @spec send_metrics(List.t(), String.t(), integer()) :: {:ok, atom()} | {:error, atom()}
  def send_metrics(results, step, concurrency) do
    partial =
      PartialResultUseCase.calculate(results,
        keep_responses: Application.get_env(:perf_analyzer, :jmeter_report, true)
      )

    GenServer.call({:global, __MODULE__}, {:results, partial, step, concurrency})
  end

  def get_metrics do
    GenServer.call({:global, __MODULE__}, :get_metrics)
  end

  def clean_metrics do
    GenServer.cast({:global, __MODULE__}, :clean)
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: {:global, __MODULE__})
  end

  @impl true
  def init(_) do
    {:ok, %{}}
  end

  @impl true
  def handle_call({:results, partial, step, concurrency}, _from, state) do
    state =
      Map.update(state, step, partial, fn acc_partial ->
        PartialResultUseCase.combine(acc_partial, partial)
      end)

    partial = state[step]

    if partial.concurrency == concurrency do
      new_state =
        Map.update(state, step, partial, fn acc_partial ->
          Statistics.calculate_p90(state[step])
        end)

      partial = new_state[step]
      mean_latency = Statistics.mean(partial.success_mean_latency, partial.success_count)

      step_result = [concurrency, partial, mean_latency]

      ReportUseCase.log_step_result(step_result)

      {:reply, :ok, new_state}
    else
      {:reply, :ok, state}
    end
  end

  @impl true
  def handle_call(:get_metrics, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_cast(:clean, _state) do
    {:noreply, %{}}
  end
end
