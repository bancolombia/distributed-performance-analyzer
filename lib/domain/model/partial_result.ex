defmodule DistributedPerformanceAnalyzer.Domain.Model.PartialResult do
  use Constructor

  @moduledoc """
  TODO Result of a step
  """
  def new(map) when is_map(map) do
    {:ok, struct(__MODULE__, map)}
  end

  constructor do
    field(:success_count, :integer, constructor: &is_integer/1, default: 0)
    field(:http_count, :integer, constructor: &is_integer/1, default: 0)
    field(:total_count, :integer, constructor: &is_integer/1, default: 0)
    field(:fail_http_count, :integer, constructor: &is_integer/1, default: 0)
    field(:protocol_error_count, :integer, constructor: &is_integer/1, default: 0)
    field(:invocation_error_count, :integer, constructor: &is_integer/1, default: 0)
    field(:error_conn_count, :integer, constructor: &is_integer/1, default: 0)
    field(:nil_conn_count, :integer, constructor: &is_integer/1, default: 0)
    field(:success_mean_latency, :integer, constructor: &is_integer/1, default: 0)
    field(:http_mean_latency, :integer, constructor: &is_integer/1, default: 0)
    field(:http_max_latency, :integer, constructor: &is_integer/1, default: 0)
    field(:success_max_latency, :integer, constructor: &is_integer/1, default: 0)
    field(:concurrency, :integer, constructor: &is_integer/1, default: 1)
    field(:times, :lists, constructor: &is_list/1, default: [])
    field(:p90, :integer, constructor: &is_integer/1, default: 0)
    field(:requests, :lists, constructor: &is_list/1, default: [])
  end
end
