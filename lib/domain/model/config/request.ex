defmodule DistributedPerformanceAnalyzer.Domain.Model.Config.Request do
  use Constructor

  @moduledoc """
  Request model
  """

  constructor do
    field(:name, :string, constructor: &is_string/1)
    field(:url, :string, constructor: &is_string/1)
    field(:method, :string, constructor: &is_string/1)
    field(:headers, :lists, constructor: &is_list/1)
    field(:body, :any)
    field(:params, :lists, constructor: &is_list/1)
    field(:timeout, :integer, constructor: &is_integer/1)
  end
end
