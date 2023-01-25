defmodule DistributedPerformanceAnalyzer.Domain.Model.ExecutionModel do
  @moduledoc """
  TODO Execution model
  """

  alias DistributedPerformanceAnalyzer.Domain.Model.Request

  @allowed_keys [
    "request",
    "steps",
    "increment",
    "duration",
    "dataset",
    "separator",
    "constant_load"
  ]

  @type t :: %__MODULE__{
          request: Request.t(),
          steps: integer(),
          increment: integer(),
          duration: float(),
          dataset: String.t(),
          separator: String.t(),
          constant_load: boolean()
        }

  defstruct [:request, :steps, :increment, :duration, :dataset, :separator, constant_load: false]
end
