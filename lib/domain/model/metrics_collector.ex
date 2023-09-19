defmodule DistributedPerformanceAnalyzer.Domain.Model.MetricsCollector do
  use Constructor

  @moduledoc """
  Metrics collector module model.

  """

  constructor do
    field(:results, String.t(), constructor: &is_string/1)
    field(:step, String.t(), constructor: &is_string/1)
    field(:concurrency, :integer, constructor: &is_integer/1)
  end
end
