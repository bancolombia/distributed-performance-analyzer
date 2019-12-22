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

    results = Enum.map(results, fn item ->
      case item do
        {latency, {:ok, %{data: _, headers: _, status: status}}} -> {:ok, latency, status}
        {latency, _} -> {:fail, latency}
        {latency, _} -> :fail
      end
    end)
      |> Enum.filter(& is_success(&1))
      |> Enum.count()

    state = Map.update(state, step, [], fn xs -> [results | xs] end)
    {:noreply, state}
  end

  @impl true
  def handle_call(:get_metrics, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_cast({:results, results, step}, state) do
    state = Map.update(state, step, [], fn xs -> [results | xs] end)
    {:noreply, state}
  end

  defp is_success(response) do
    case response do
      {:ok, latency, status} -> true
      _ -> false
    end
  end

end
