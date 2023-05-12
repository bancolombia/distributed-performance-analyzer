defmodule DistributedPerformanceAnalyzer.Domain.Behaviours.DataSetBehaviour do
  @moduledoc """
  Definitions of operations on datasets
  """

  @callback parse_csv(path :: term, args :: term) :: {:ok, result :: term} | {:error, reason :: term}
end
