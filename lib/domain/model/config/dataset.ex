defmodule DistributedPerformanceAnalyzer.Domain.Model.Config.Dataset do
  use Constructor

  @moduledoc """
  Dataset model
  """

  constructor do
    field(:path, String.t(), constructor: &is_string/1)
    field(:separator, String.t(), constructor: &is_string/1, default: ",")
    field(:ordered, :boolean, constructor: &is_boolean/1, default: false)
  end
end
