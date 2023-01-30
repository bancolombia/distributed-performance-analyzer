defmodule DistributedPerformanceAnalyzer.Domain.Model.DataSet do
  @moduledoc """
  Dataset
  """

  @enforce_keys [:path, :args]

  @allowed_keys [
    "path",
    "args"
  ]

  @type t :: %__MODULE__{
          path: String.t(),
          args: map()
        }

  defstruct [
    :path,
    :args
  ]
end