defmodule DistributedPerformanceAnalyzer.Domain.Behaviours.Reports.Report do
  @moduledoc """
  Definitions of operations reports
  """

  @type data :: String.t()
  @type file_name :: String.t()
  @type header :: String.t()
  @type print :: boolean
  @type result :: String.t()
  @type reason :: String.t()

  @callback save_csv(data, file_name, header, print) :: {:ok, result} | {:error, reason}
end
