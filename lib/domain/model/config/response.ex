defmodule DistributedPerformanceAnalyzer.Domain.Model.Config.Response do
  use Constructor

  @moduledoc """
  Response model
  """

  constructor do
    field(:status, :integer, constructor: &is_integer/1)
    field(:message, String.t(), constructor: &is_string/1)
    field(:headers, :list, constructor: &is_list/1)
    field(:time, :integer, constructor: &is_integer/1)
    field(:connection_time, :integer, constructor: &is_integer/1)
  end
end
