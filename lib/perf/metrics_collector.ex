defmodule Perf.MetricsCollector do
  @moduledoc false
  use GenServer

  def send_metrics(results, step, concurrency) do
    partial = PartialResult.calculate(results)
    GenServer.call({:global, __MODULE__}, {:results, partial, step, concurrency})
  end

  def get_metrics do
    GenServer.call({:global, __MODULE__}, :get_metrics)
  end

  def clean_metrics do
    GenServer.cast({:global, __MODULE__}, :clean)
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: {:global, __MODULE__})
  end

  @impl true
  def init(_) do
    {:ok, %{}}
  end

  @impl true
  def handle_call({:results, partial = %PartialResult{}, step, concurrency}, _from, state) do
    state = Map.update(state, step, partial, fn acc_partial -> PartialResult.combine(acc_partial, partial) end)
    partial = state[step]
    if partial.concurrency == concurrency do
      mean_latency = partial.success_mean_latency / (partial.success_count + 0.00001)
      #IO.puts("concurrency, success_count -- mean_latency -- fail_http_count, protocol_error_count, error_conn_count, nil_conn_count")
      IO.puts(
        "#{concurrency}, #{partial.success_count} -- #{round(mean_latency)}ms -- #{partial.fail_http_count}, #{
          partial.protocol_error_count
        }, #{partial.error_conn_count}, #{partial.nil_conn_count}"
      )
    end
    {:reply, :ok, state}
  end

  @impl true
  def handle_call(:get_metrics, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_cast(:clean, state) do
    {:noreply, %{}}
  end

end
