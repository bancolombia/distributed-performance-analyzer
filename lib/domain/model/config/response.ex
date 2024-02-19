defmodule DistributedPerformanceAnalyzer.Domain.Model.Config.Response do
  use Constructor

  @moduledoc """
  Response model
  """

  constructor do
    field(:status, :integer, constructor: &is_integer/1)
    field(:message, String.t(), constructor: &is_string_or_nil/1)
    field(:elapsed, :integer, constructor: &is_integer/1)
    field(:timestamp, :integer, constructor: &is_integer/1)
    field(:connection_time, :integer, constructor: &is_integer/1)
    field(:content_type, String.t(), constructor: &is_string_or_nil/1)
    field(:received_bytes, :integer, constructor: &is_integer/1)
  end
end
