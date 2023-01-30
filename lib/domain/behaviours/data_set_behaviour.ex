defmodule DistributedPerformanceAnalyzer.Domain.Behaviours.DataSetBehaviour do
  @moduledoc """
  Definitions of operations on datasets
  """

  @callback load(path :: term, type :: term, args :: term) ::
              {:ok, result :: term} | {:error, reason :: term}
end
