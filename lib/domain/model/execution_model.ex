defmodule DistributedPerformanceAnalyzer.Domain.Model.ExecutionModel do
  use Constructor

  @moduledoc """
  TODO Execution model
  """

  alias DistributedPerformanceAnalyzer.Domain.Model.Request

  constructor do
    field(:request, Request.t())
    field(:steps, :integer, constructor: &is_integer/1)
    field(:increment, :integer, constructor: &is_integer/1)
    field(:duration, :float, constructor: &is_float/1)
    field(:dataset, :string, constructor: &is_string/1)
    field(:separator, :string, constructor: &is_string/1, default: ",")
    field(:constant_load, :boolean, constructor: &is_boolean/1, default: false)
  end
end
