defmodule Perf.Execution do
  @moduledoc false
  use Task, restart: :transient

  defstruct [:request, :steps, :increment, :duration, :collector]

  def start_link(conf = %Perf.Execution{}) do
    Task.start_link(__MODULE__, :start, [conf])
  end

  def start(%Perf.Execution{request: req, duration: duration, collector: collector, steps: steps, increment: inc}) do
    1..steps
    |> Enum.map(fn x -> {x, x * inc} end)
    |> Enum.map(fn {x, concurrency} -> {req, "Step-#{x}", duration, concurrency, collector} end)
    |> Enum.each(fn step_conf ->
      IO.puts("Initiating #{elem(step_conf, 1)}, with #{elem(step_conf, 3)} actors")
      Perf.ConnectionPool.ensure_capacity(elem(step_conf, 3))
      Perf.LoadStep.start_step(step_conf)
    end)
    Perf.MetricsAnalyzer.compute_metrics()
  end

end
