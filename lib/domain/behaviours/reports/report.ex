defmodule DistributedPerformanceAnalyzer.Domain.Behaviours.Reports.Report do
  @moduledoc """
  Definitions of operations reports
  """

  @callback save_csv(data :: term, path :: term, header :: term, print :: term, print :: fun) ::
              {:ok, result :: term} | {:error, reason :: term}
end
