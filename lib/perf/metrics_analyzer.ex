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
      concurrency = Enum.count(Map.get(metrics, step))
      success_responses = Map.get(metrics, step)
                  |> Enum.flat_map(fn x -> x end)
                  |> Enum.filter(& is_success(&1))
                  |> Enum.count()
      throughput = success_responses / duration_segs
      {step, throughput, concurrency}
    end)
    sorted_curve = Enum.sort(curve, &(elem(&1, 2) <=  elem(&2, 2)))

    IO.puts("Total steps: #{steps_count}")
    IO.puts("Total duration: #{steps_count * duration_segs} seconds")
    Enum.each(sorted_curve, fn {step, throughput, concurrency} ->
      IO.puts("#{concurrency}, #{throughput}")
    end)

    {:noreply, nil}
  end

  defp is_success(response) do
    case response do
      {lat, {:ok, _}} -> true
      _ -> false
    end

  end

end
