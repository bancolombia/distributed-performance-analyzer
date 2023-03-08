defmodule DistributedPerformanceAnalyzer.Domain.Model.MetricsCollector do
  @moduledoc """
  Metrics Collector
  """
  @enforce_keys [:results, :step, :concurrency]

  @allowed_keys ["results", "step", "concurrency"]

  @type t :: %__MODULE__{
          results: String.t(),
          step: String.t(),
          concurrency: Integer.t()
        }

  defstruct [
    :results,
    :step,
    :concurrency
  ]
end
