defmodule DistributedPerformanceAnalyzer.Domain.Model.User do
  use Constructor
  alias DistributedPerformanceAnalyzer.Domain.Model.Config.Request

  @moduledoc """
  User model
  """

  constructor do
    field(:id, String.t(), constructor: &is_string/1)
    field(:request, Request.t(), constructor: &Request.new/1)
    field(:dataset_name, :atomics | String.t())
  end
end
