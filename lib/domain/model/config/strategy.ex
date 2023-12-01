defmodule DistributedPerformanceAnalyzer.Domain.Model.Config.Strategy do
  use Constructor

  @moduledoc """
  Strategy model
  """

  constructor do
    field(:steps, :integer, constructor: &is_integer/1)
    field(:duration, :integer, constructor: &is_integer/1)
    field(:initial, :integer, constructor: &is_integer/1, default: 0)
    field(:increment, :integer, constructor: &is_integer/1)
    field(:constant_load, :boolean, constructor: &is_boolean/1, default: false)
  end
end
