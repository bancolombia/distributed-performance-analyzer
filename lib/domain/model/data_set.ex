defmodule DistributedPerformanceAnalyzer.Domain.Model.DataSet do
  @moduledoc """
  Dataset
  """

  @enforce_keys [:path, :type]

  @allowed_keys [
    "path",
    "type",
    "args"
  ]

  @type t :: %__MODULE__{
          path: String.t(),
          type: atom(),
          args: any()
        }

  defstruct [
    :path,
    :type,
    :args
  ]
end
