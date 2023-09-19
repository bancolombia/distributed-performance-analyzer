defmodule DistributedPerformanceAnalyzer.Domain.Model.Config.Request do
  use Constructor

  @moduledoc """
  Request model
  """

  constructor do
    field(:url, String.t(), constructor: &is_string/1)
    field(:method, String.t(), constructor: &is_string/1)
    field(:headers, :lists, constructor: &is_list/1)
    field(:body, :any)
    field(:params, :lists, constructor: &is_list/1, default: [], enforce: false)
    field(:timeout, :integer, constructor: &is_integer/1, default: 30, enforce: false)
  end
end
