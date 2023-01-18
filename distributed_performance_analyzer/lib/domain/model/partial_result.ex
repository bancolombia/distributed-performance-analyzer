defmodule DistributedPerformanceAnalyzer.Domain.Model.PartialResult do
  @moduledoc """
  TODO Result of a step
  """

  defstruct success_count: 0,
            http_count: 0,
            total_count: 0,
            fail_http_count: 0,
            protocol_error_count: 0,
            invocation_error_count: 0,
            error_conn_count: 0,
            nil_conn_count: 0,
            success_mean_latency: 0,
            http_mean_latency: 0,
            http_max_latency: 0,
            success_max_latency: 0,
            concurrency: 1,
            times: [],
            p90: 0,
            requests: []

  def new() do
    %__MODULE__{}
  end
end
