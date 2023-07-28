defmodule DistributedPerformanceAnalyzer.Domain.Model.Request do
  use Constructor

  @moduledoc """
  TODO Request
  """

  constructor do
    field(:method, :string, constructor: &is_string/1, enforce: true)
    field(:path, :string, constructor: &is_string/1)
    field(:headers, :lists, constructor: &is_list/1)
    field(:body, :any)
    field(:url, :string, constructor: &is_string/1, enforce: true)
    field(:item, :any)
  end
end
