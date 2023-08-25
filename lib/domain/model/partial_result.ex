defmodule DistributedPerformanceAnalyzer.Domain.Model.PartialResult do
  use Constructor

  @moduledoc """
  TODO Result of a step
  """
  constructor do
    field(:success_count, :integer, constructor: &is_integer/1, default: 0)
    field(:redirect_count, :integer, constructor: &is_integer/1, default: 0)
    field(:bad_request_count, :integer, constructor: &is_integer/1, default: 0)
    field(:server_error_count, :integer, constructor: &is_integer/1, default: 0)
    field(:fail_http_count, :integer, constructor: &is_integer/1, default: 0)
    field(:protocol_error_count, :integer, constructor: &is_integer/1, default: 0)
    field(:invocation_error_count, :integer, constructor: &is_integer/1, default: 0)
    field(:error_conn_count, :integer, constructor: &is_integer/1, default: 0)
    field(:nil_conn_count, :integer, constructor: &is_integer/1, default: 0)
    field(:error_count, :integer, constructor: &is_integer/1, default: 0)
    field(:total_count, :integer, constructor: &is_integer/1, default: 0)
    field(:http_avg_latency, :integer, constructor: &is_integer/1, default: 0)
    field(:http_max_latency, :integer, constructor: &is_integer/1, default: 0)
    field(:http_error_count, :integer, constructor: &is_integer/1, default: 0)
    field(:concurrency, :integer, constructor: &is_integer/1, default: 1)
    field(:times, :lists, constructor: &is_list/1, default: [])
    field(:success_times, :lists, constructor: &is_list/1, default: [])
    field(:min_latency, :integer, constructor: &is_integer/1, default: 0)
    field(:avg_latency, :integer, constructor: &is_integer/1, default: 0)
    field(:max_latency, :integer, constructor: &is_integer/1, default: 0)
    field(:p90_latency, :integer, constructor: &is_integer/1, default: 0)
    field(:p95_latency, :integer, constructor: &is_integer/1, default: 0)
    field(:p99_latency, :integer, constructor: &is_integer/1, default: 0)
    field(:throughput, :integer, constructor: &is_integer/1, default: 0)
    field(:requests, :lists, constructor: &is_list/1, default: [])
  end
end
