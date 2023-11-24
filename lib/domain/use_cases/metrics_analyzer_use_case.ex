defmodule DistributedPerformanceAnalyzer.Domain.UseCase.MetricsAnalyzerUseCase do
  @moduledoc """
  Metrics Analyzer use case
  """
  use GenServer
  require Logger
  alias DistributedPerformanceAnalyzer.Domain.Model.Config.Strategy

  alias DistributedPerformanceAnalyzer.Domain.UseCase.{
    MetricsCollectorUseCase,
    Reports.ReportUseCase,
    Config.ConfigUseCase
  }

  alias DistributedPerformanceAnalyzer.Utils.{Statistics, DataTypeUtils}

  def compute_metrics do
    GenServer.cast(__MODULE__, :compute)
  end

  def start_link(_) do
    Logger.debug("Starting metrics analyzer server...")
    #    TODO: do parallel
    scenario = ConfigUseCase.get(:scenarios) |> Enum.at(0)
    GenServer.start_link(__MODULE__, scenario, name: __MODULE__)
  end

  @impl true
  def init(scenario) do
    {:ok, scenario.strategy}
  end

  @impl true
  def handle_cast(:compute, %Strategy{duration: duration}) do
    step_duration = Statistics.millis_to_seconds(duration)
    metrics = MetricsCollectorUseCase.get_metrics()

    steps_count = Map.keys(metrics) |> Enum.count()
    steps = Map.values(metrics) |> Enum.sort(&(&1.concurrency <= &2.concurrency))

    success_request_count =
      Enum.reduce(steps, 0, &(&1.success_count + &2))

    failed_request_count =
      Enum.reduce(steps, 0, &(&1.error_count + &2))

    total_duration = Statistics.duration(steps_count, step_duration)
    total_data = [steps_count, success_request_count, failed_request_count, total_duration]

    ReportUseCase.init(steps, total_data)
    MetricsCollectorUseCase.clean_metrics()

    {:stop, :normal, nil}
  end

  def response_for_code(status) when status >= 200 and status < 400, do: "OK"
  def response_for_code(_status), do: "ERROR"
  def success?(status) when status >= 200 and status < 400, do: true
  def success?(_status), do: false
  def with_failure(status, _body) when status >= 200 and status < 400, do: nil
  def with_failure(_status, body), do: DataTypeUtils.format_failure(body)
end
