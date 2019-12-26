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
  def handle_cast(:compute, %Perf.Execution{duration: duration}) do
    duration_segs = duration / 1000
    metrics = MetricsCollector.get_metrics()
    steps = Map.keys(metrics)
    steps_count =  Enum.count(steps)

    curve = Enum.map(steps, fn step ->
      results_list = Map.get(metrics, step)
      concurrency = Enum.count(results_list)
      {success_responses, latency} = results_list
                  |> Enum.reduce({0, 0}, fn {success_count, mean_latency, _}, {succ_acc, lat_acc} -> {success_count + succ_acc, mean_latency + lat_acc } end)
      throughput = success_responses / duration_segs
      lat_total = latency / concurrency

      max_latency = results_list
        |> Enum.reduce(0, fn {_, _, latency},
           acc -> if latency > acc do latency else acc end end)

      {step, throughput, concurrency, lat_total, max_latency}
    end)
    sorted_curve = Enum.sort(curve, &(elem(&1, 2) <=  elem(&2, 2)))

    IO.puts("Total steps: #{steps_count}")
    IO.puts("Total duration: #{steps_count * duration_segs} seconds")
    Enum.each(sorted_curve, fn {step, throughput, concurrency, lat_total, max_latency} ->
      IO.puts("#{concurrency}, #{throughput} -- #{lat_total}ms -- #{max_latency}ms")
    end)

    {:stop, :normal, nil}
  end

  defp is_success(response) do
    case response do
      {:ok, latency, status} -> true
      _ -> false
    end
  end

end
