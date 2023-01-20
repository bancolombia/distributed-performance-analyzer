defmodule DistributedPerformanceAnalyzer.Domain.Model.Request do
  @moduledoc """
  TODO Request
  """

  defstruct [:method, :path, :headers, :body, :url, :item]

  def new(method, path, headers, body, url, item) do
    {:ok,
     %__MODULE__{method: method, path: path, headers: headers, body: body, url: url, item: item}}
  end
end
