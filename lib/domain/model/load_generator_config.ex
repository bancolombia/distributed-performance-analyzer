defmodule DistributedPerformanceAnalyzer.Domain.Model.LoadGeneratorConfig do
  use Constructor

  @moduledoc """
  Load Generator Conf
  """

  alias DistributedPerformanceAnalyzer.Domain.Model.Request

  constructor do
    field(:method, String.t(), constructor: &is_string/1, enforce: true)
    field(:path, String.t(), constructor: &is_string/1, enforce: true)
    field(:headers, :lists, constructor: &is_list/1, default: "")
    field(:body, :any, default: "")
  end
end
