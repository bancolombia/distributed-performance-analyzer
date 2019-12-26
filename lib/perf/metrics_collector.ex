defmodule Perf.MetricsCollector do
  @moduledoc false
  use GenServer

  def send_metrics(results, step) do
    GenServer.cast(__MODULE__, {:results, results, step})
  end

  def compute_metrics() do
    GenServer.cast(__MODULE__, :compute)
  end

  def get_metrics do
    GenServer.call(__MODULE__, :get_metrics)
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl true
  def init(_) do
    {:ok, %{}}
  end

  @impl true
  def handle_cast({:results, results, step}, state) do
    results = results
      |> Enum.filter(& is_success(&1))

    success_count = Enum.count(results)
    mean_latency = ((results
      |> Enum.reduce(0, fn {latency, _}, acc -> latency + acc end)) / success_count) / 1000
    #IO.puts("metrics for step: #{step}, #{results}")

    max_latency = (results
    |> Enum.reduce(0, fn {latency, _}, acc -> if latency > acc do
                                                latency
                                              else
                                                acc
                                              end end)) / 1000

    state = Map.update(state, step, [{success_count, mean_latency, max_latency}], fn xs -> [{success_count, mean_latency, max_latency} | xs] end)
    #IO.puts(inspect(state))
    {:noreply, state}
  end

  @impl true
  def handle_call(:get_metrics, _from, state) do
    {:reply, state, state}
  end

  defp is_success(response) do
    case response do
      {latency, {:ok, status}} -> true
      _ -> false
    end
  end

end
