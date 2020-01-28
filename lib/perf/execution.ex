defmodule Perf.Execution do
  @moduledoc false
  use GenServer

  defstruct [:request, :steps, :increment, :duration, :collector]

  def start_link(%{analyzer: analyzer, pool: pool, load_step: load_step}) do
    GenServer.start_link(__MODULE__, %{analyzer: analyzer, pool: pool, load_step: load_step, actual_step: 1, steps: 0}, name: __MODULE__)
  end

  def launch_execution() do
    GenServer.cast(__MODULE__, :launch_execution)
  end

  @impl true
  def init(state) do
    IO.puts("Initializing Perf.Execution...")
    %{steps: steps} = Perf.ExecutionConf.get
    {:ok, %{state | steps: steps}}
  end

  @impl true
  def handle_cast(:launch_execution, conf) do
    GenServer.cast(self(), :continue_execution)
    {:noreply, %{conf | actual_step: 1}}
  end

  @impl true
  def handle_cast(:continue_execution, state = %{actual_step: actual_step, steps: steps}) when actual_step <= steps do
    Perf.ExecutionConf.get
      |> create_step_conf(state.actual_step)
      |> start_step(state.pool, state.load_step)
    {:noreply, %{state | actual_step: state.actual_step + 1}}
  end

  @impl true
  def handle_cast(:continue_execution, state = %{actual_step: actual_step, steps: steps}) when actual_step > steps do
    state.analyzer.compute_metrics()
    {:noreply, %{state | actual_step: 1}}
  end

  defp create_step_conf(conf = %Perf.Execution{}, step_num) do
    concurrency = step_num * conf.increment
    {conf.request, "Step-#{step_num}", conf.duration, concurrency, conf.collector}
  end

  defp start_step(step_conf, pool, load_step) do
    IO.puts("Initiating #{elem(step_conf, 1)}, with #{elem(step_conf, 3)} actors")
    Task.start_link(fn ->
      load_step.start_step(step_conf, pool)
      GenServer.cast(__MODULE__, :continue_execution)
    end)
  end


end
