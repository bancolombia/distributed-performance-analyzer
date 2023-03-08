defmodule DistributedPerformanceAnalyzer.Domain.Behaviours.MetricsCollectorBehaviour do
  @moduledoc """
  Definitions of operations on Metrics Collector
  """

  @callback send_metrics(results :: term, step :: term, concurrency :: term) ::
              {:ok, result :: term} | {:error, reason :: term}
end
