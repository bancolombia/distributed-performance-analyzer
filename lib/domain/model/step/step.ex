defmodule DistributedPerformanceAnalyzer.Domain.Model.Config.Step do
  use Constructor
  alias DistributedPerformanceAnalyzer.Domain.Model.Scenario

  @moduledoc """
  Step model
  """

  constructor do
    field(:number, :integer, constructor: &is_integer/1)
    field(:scenario, Scenario.t(), constructor: &Scenario.new/1)
  end
end
