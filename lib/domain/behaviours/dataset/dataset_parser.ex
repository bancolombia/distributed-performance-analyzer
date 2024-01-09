defmodule DistributedPerformanceAnalyzer.Domain.Behaviours.Dataset.DatasetParser do
  @moduledoc """
  Definitions of operations on datasets
  """

  @type path :: String.t()
  @type separator :: String.t()
  @type result :: List.t()
  @type reason :: String.t()

  @callback parse_csv(path, separator) :: {:ok, result} | {:error, reason}
end
