defmodule Perf.MetricsAnalyzer do
  @moduledoc false
  use GenServer
  alias Perf.MetricsCollector

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
    duration_segs = duration / 1000
    metrics = MetricsCollector.get_metrics()
    steps = Map.keys(metrics)
    steps_count =  Enum.count(steps)

    curve = Enum.map(steps, fn step ->
      #partial = IO.inspect(Map.get(metrics, step))
      step_num = String.split(step, "-") |> Enum.at(1) |> String.to_integer()
      partial = Map.get(metrics, step)
      throughput = partial.success_count / (duration_segs)
      mean_latency = partial.success_mean_latency / (partial.success_count + 0.00001)
      mean_latency_http = partial.http_mean_latency / (partial.http_count + 0.00001)
      {step_num, throughput, partial.concurrency, mean_latency, partial.success_max_latency, mean_latency_http, partial}
    end)

    total_success_count = Enum.reduce(steps, 0, fn step, acc -> Map.get(metrics, step).success_count + acc end)
    sorted_curve = Enum.sort(curve, &(elem(&1, 0) <=  elem(&2, 0)))

    Perf.Application.add_to(sorted_curve)
    {:stop, :normal, nil}
  end

  defp is_success(response) do
    case response do
      {:ok, latency, status} -> true
      _ -> false
    end
  end

end
