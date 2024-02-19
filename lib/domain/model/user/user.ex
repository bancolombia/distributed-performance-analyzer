defmodule DistributedPerformanceAnalyzer.Domain.Model.User do
  use Constructor
  alias DistributedPerformanceAnalyzer.Domain.Model.Config.Request

  @moduledoc """
  User model
  """

  constructor do
    field(:request, Request.t(), constructor: &Request.new/1)

    field(:dataset_name, String.t(),
      constructor: &is_string_or_nil/1,
      default: nil,
      enforce: false
    )
  end
end
