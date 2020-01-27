defmodule Perf.MetricsCollector do
  @moduledoc false
  use GenServer

  def send_metrics(results, step) do
    GenServer.cast({:global, __MODULE__}, {:results, results, step})
  end

  def get_metrics do
    GenServer.call({:global, __MODULE__}, :get_metrics)
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: {:global, __MODULE__})
  end

  @impl true
  def init(_) do
    {:ok, %{}}
  end

  @impl true
  def handle_cast({:results, results, step}, state) do
    results = Enum.filter(results, & is_success(&1))
    success_count = Enum.count(results)
    if success_count > 0 do
      mean_latency = mean_latency(results, success_count)
      max_latency = max_latency(results)
      state = Map.update(state, step, [{success_count, mean_latency, max_latency}], fn xs -> [{success_count, mean_latency, max_latency} | xs] end)
      {:noreply, state}
    else
      {:noreply, state}
    end
  end

  defp mean_latency(results, success_count) do
    ((results |> Enum.reduce(0, fn {latency, _}, acc -> latency + acc end)) / success_count) / 1000
  end

  defp max_latency(results) do
    Enum.reduce(results, 0, &decide_max/2) / 1000
  end

  defp decide_max({latency, _}, acc) do
    max(latency, acc)
  end

  @impl true
  def handle_call(:get_metrics, _from, state) do
    {:reply, state, state}
  end

  defp is_success({latency, {:ok, status}}), do: true
  defp is_success(_), do: false

end
