defmodule DistributedPerformanceAnalyzer.Domain.Model.ExecutionModel do
  @moduledoc """
  TODO Execution model
  """

  defstruct [:request, :steps, :increment, :duration, :dataset, :separator, constant_load: false]
end
