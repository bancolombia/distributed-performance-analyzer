defmodule Perf.Execution do
  @moduledoc false
  use GenServer

  defstruct [:request, :steps, :increment, :duration, :collector]

  def start_link(%{analyzer: analyzer, pool: pool, load_step: load_step}) do
    GenServer.start_link(__MODULE__, %{analyzer: analyzer, pool: pool, load_step: load_step}, name: __MODULE__)
  end

  def launch_execution() do
    GenServer.cast(__MODULE__, :launch_execution)
  end

  @impl true
  def init(%{analyzer: analyzer, pool: pool, load_step: load_step}) do
    IO.puts("Initializing Perf.Execution...")
    {:ok, %{analyzer: analyzer, pool: pool, load_step: load_step}}
  end

  @impl true
  def handle_cast(
        :launch_execution,
        %{analyzer: analyzer, pool: pool, load_step: load_step}) do
    %Perf.Execution{request: req, duration: duration, collector: collector, steps: steps, increment: inc} = Perf.ExecutionConf.get
    1..steps
    |> Enum.map(fn x -> {x, x * inc} end)
    |> Enum.map(fn {x, concurrency} -> {req, "Step-#{x}", duration, concurrency, collector} end)
    |> Enum.each(fn step_conf ->
      IO.puts("Initiating #{elem(step_conf, 1)}, with #{elem(step_conf, 3)} actors")
      IO.inspect(pool.ensure_capacity(elem(step_conf, 3)))
      load_step.start_step(step_conf)
    end)
    analyzer.compute_metrics()
    {:noreply, %{analyzer: analyzer, pool: pool, load_step: load_step}}
  end


end
