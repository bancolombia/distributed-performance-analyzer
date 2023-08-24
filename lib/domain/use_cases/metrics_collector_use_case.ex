defmodule DistributedPerformanceAnalyzer.Domain.UseCase.MetricsCollectorUseCase do
  @moduledoc """
  Use case metrics collector.
  The metrics collector model module is called.

  The data executed by each step is captured and sent to the partialResult module,
  the result row of this step is also printed.
  """

  alias DistributedPerformanceAnalyzer.Domain.UseCase.{
    Reports.ReportUseCase,
    PartialResultUseCase
  }

  alias DistributedPerformanceAnalyzer.Domain.Model.ExecutionModel
  alias DistributedPerformanceAnalyzer.Utils.Statistics

  use GenServer
  require Logger

  @spec send_metrics(List.t(), String.t(), integer()) :: {:ok, atom()} | {:error, atom()}
  def send_metrics(results, step, concurrency) do
    partial =
      PartialResultUseCase.calculate(results,
        keep_responses:
          Application.get_env(:distributed_performance_analyzer, :jmeter_report, true)
      )

    GenServer.call({:global, __MODULE__}, {:results, partial, step, concurrency})
  end

  def get_metrics do
    GenServer.call({:global, __MODULE__}, :get_metrics)
  end

  def clean_metrics do
    GenServer.cast({:global, __MODULE__}, :clean)
  end

  def start_link(conf) do
    Logger.debug("Starting metrics collector server...")
    GenServer.start_link(__MODULE__, conf, name: {:global, __MODULE__})
  end

  @impl true
  def init(%ExecutionModel{duration: step_duration}) do
    {:ok, {Statistics.millis_to_seconds(step_duration), %{}}}
  end

  @impl true
  def handle_call({:results, partial, step, concurrency}, _from, state) do
    {step_duration, results} = state

    results =
      Map.update(results, step, partial, fn acc_partial ->
        PartialResultUseCase.combine(acc_partial, partial)
      end)

    partial = results[step]

    if partial.concurrency == concurrency do
      new_state =
        Map.update(results, step, partial, fn _acc_partial ->
          p90 = Statistics.percentile(results[step].times, 90) || 0
          p95 = Statistics.percentile(results[step].times, 95) || 0
          p99 = Statistics.percentile(results[step].times, 99) || 0
          %{results[step] | p90: p90, p95: p95, p99: p99, times: []}
        end)

      partial = new_state[step]
      mean_latency = Statistics.mean(partial.success_mean_latency, partial.success_count)
      tps = partial.success_count / step_duration

      errors =
        partial.protocol_error_count + partial.invocation_error_count + partial.error_conn_count +
          partial.nil_conn_count

      ReportUseCase.log_step_result({partial, mean_latency, tps, errors})

      {:reply, :ok, {step_duration, new_state}}
    else
      {:reply, :ok, {step_duration, results}}
    end
  end

  @impl true
  def handle_call(:get_metrics, _from, {step_duration, state}) do
    {:reply, state, {step_duration, state}}
  end

  @impl true
  def handle_cast(:clean, {step_duration, _state}) do
    {:noreply, {step_duration, %{}}}
  end
end
