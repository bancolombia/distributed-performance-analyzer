defmodule DistributedPerformanceAnalyzer.Domain.Model.LoadGeneratorConfig do
  @moduledoc """
  Load Generator Conf
  """

  alias DistributedPerformanceAnalyzer.Domain.Model.Request

  @allowed_keys [
    "method",
    "path",
    "headers",
    "body"
  ]

  @enforce_keys [:method, :path]

  @type t :: %__MODULE__{
          method: String.t(),
          path: String.t(),
          headers: list(),
          body: any()
        }

  defstruct [:method, :path, :headers, :body]

  @spec new(String.t(), String.t()) :: DistributedPerformanceAnalyzer.Domain.Model.Request.t()
  def new(method, path) do
    %Request{method: method, path: path, headers: [], body: "", url: ""}
  end
end
