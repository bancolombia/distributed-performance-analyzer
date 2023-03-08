defmodule DistributedPerformanceAnalyzer.Domain.Model.FileSystem do

  @moduledoc """
  Model is responsible for managing multiple files or directories
  """

  @enforce_keys [:path]

  @allowed_keys [
    "path",
    "data"
  ]

  @type t :: %__MODULE__{
          path: String.t(),
          data: any()
        }

  defstruct [
    :path,
    :data
  ]
end
