defmodule DistributedPerformanceAnalyzer.Domain.Behaviours.Dataset.DatasetParser do
  @moduledoc """
  Definitions of operations on datasets
  """

  @callback file_exists?(path :: term) :: boolean
  @callback parse_csv(path :: term, args :: term) ::
              {:ok, result :: term} | {:error, reason :: term}
end
