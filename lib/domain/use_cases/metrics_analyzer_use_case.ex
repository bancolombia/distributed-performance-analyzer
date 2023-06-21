defmodule DistributedPerformanceAnalyzer.Domain.UseCase.MetricsAnalyzerUseCase do
  @moduledoc """
  Metrics Analyzer use case
  """
  use GenServer
  alias DistributedPerformanceAnalyzer.Domain.Model.ExecutionModel
  alias DistributedPerformanceAnalyzer.Domain.UseCase.MetricsCollectorUseCase
  alias DistributedPerformanceAnalyzer.Domain.UseCase.Reports.ReportUseCase
  alias DistributedPerformanceAnalyzer.Utils.{Statistics, DataTypeUtils}

  def compute_metrics do
    GenServer.cast(__MODULE__, :compute)
  end

  def start_link(conf) do
    GenServer.start_link(__MODULE__, conf, name: __MODULE__)
  end

  @impl true
  def init(conf) do
    {:ok, conf}
  end

  @impl true
  def handle_cast(:compute, %ExecutionModel{duration: duration}) do
    duration_secs = Statistics.millis_to_seconds(duration)
    metrics = MetricsCollectorUseCase.get_metrics()
    steps = Map.keys(metrics)
    steps_count = Enum.count(steps)

    curve =
      Enum.map(
        steps,
        fn step ->
          # partial = IO.inspect(Map.get(metrics, step))
          step_num =
            String.split(step, "-")
            |> Enum.at(1)
            |> String.to_integer()

          partial = Map.get(metrics, step)
          throughput = Statistics.throughput(partial.success_count, duration_secs)

          mean_latency = Statistics.mean(partial.success_mean_latency, partial.success_count)

          mean_latency_http = Statistics.mean(partial.http_mean_latency, partial.http_count)

          {
            step_num,
            throughput,
            partial.concurrency,
            mean_latency,
            partial.success_max_latency,
            mean_latency_http,
            partial
          }
        end
      )

    total_success_count =
      Enum.reduce(steps, 0, fn step, acc -> Map.get(metrics, step).success_count + acc end)

    sorted_curve = Enum.sort(curve, &(elem(&1, 0) <= elem(&2, 0)))
    total_duration = Statistics.duration(steps_count, duration_secs)

    total_data = [steps_count, total_success_count, total_duration]

    ReportUseCase.init(sorted_curve, total_data)

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
