defmodule DistributedPerformanceAnalyzer.Domain.Model.Request do
  @moduledoc """
  TODO Request
  """

  defstruct [:method, :path, :headers, :body, :url, :item]

  def new() do
    %__MODULE__{}
  end
end
