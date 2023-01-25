defmodule DistributedPerformanceAnalyzer.Domain.Model.Request do
  @moduledoc """
  TODO Request
  """

  @enforce_keys [:method, :url]
  @allowed_keys ["method", "path", "headers", "body", "url", "item"]

  @type t :: %__MODULE__{
          method: String.t(),
          path: String.t(),
          headers: list(),
          body: any(),
          url: String.t(),
          item: any()
        }

  defstruct [:method, :path, :headers, :body, :url, :item]
end
