defmodule DistributedPerformanceAnalyzer.Domain.Model.Execution do
  @moduledoc """
  TODO Execution strategy
  """

  defstruct [:request, :steps, :increment, :duration, :dataset, :separator, constant_load: false]

  def new() do
    %__MODULE__{}
  end
end
