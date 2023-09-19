defmodule DistributedPerformanceAnalyzer.Domain.Model.Request do
  use Constructor

  @moduledoc """
  TODO Request
  """

  constructor do
    field(:method, String.t(), constructor: &is_string/1, enforce: true)
    field(:path, String.t(), constructor: &is_string/1)
    field(:headers, :lists, constructor: &is_list/1)
    field(:body, :any)
    field(:url, String.t(), constructor: &is_string/1, enforce: true)
    field(:item, :any)
  end
end
