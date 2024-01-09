defmodule DistributedPerformanceAnalyzer.Domain.UseCase.MetricsCollectorUseCase do
  @moduledoc """
  Use case metrics collector.
  The metrics collector model module is called.

  The data executed by each step is captured and sent to the partialResult module,
  the result row of this step is also printed.
  """

  alias DistributedPerformanceAnalyzer.Domain.Model.Config.Strategy

  alias DistributedPerformanceAnalyzer.Domain.UseCase.{
    PartialResultUseCase,
    Config.ConfigUseCase
  }

  alias DistributedPerformanceAnalyzer.Utils.Statistics

  use GenServer
  require Logger

  def start_link(_) do
    Logger.debug("Starting metrics collector server...")
    #    TODO: do parallel
    scenario = ConfigUseCase.get(:scenarios) |> Enum.at(0)
    GenServer.start_link(__MODULE__, scenario.strategy, name: {:global, __MODULE__})
  end

  @spec send_metrics(List.t(), String.t(), integer()) :: {:ok, atom()} | {:error, atom()}
  def send_metrics(results, step, concurrency) do
    partial =
      PartialResultUseCase.calculate(results,
        keep_responses: ConfigUseCase.get(:jmeter_report, true)
      )

    GenServer.call({:global, __MODULE__}, {:results, partial, step, concurrency})
  end

  def get_metrics do
    GenServer.call({:global, __MODULE__}, :get_metrics)
  end

  def clean_metrics do
    GenServer.cast({:global, __MODULE__}, :clean)
  end

  @impl true
  def init(%Strategy{duration: step_duration}) do
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
          PartialResultUseCase.consolidate(partial, step_duration)
        end)

      partial = new_state[step]

      PartialResultUseCase.print_status(partial)

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
