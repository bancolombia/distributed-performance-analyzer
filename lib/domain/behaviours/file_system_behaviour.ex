defmodule DistributedPerformanceAnalyzer.Domain.Behaviours.FileSystemBehaviour do
  @moduledoc """
  Definitions of operations on files
  """

  @callback write_to_file(data :: term, path :: term, header :: term, print :: term, print :: fun) ::
              {:ok, result :: term} | {:error, reason :: term}
end
