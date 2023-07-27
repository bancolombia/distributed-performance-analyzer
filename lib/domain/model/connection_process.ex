defmodule DistributedPerformanceAnalyzer.Domain.Model.ConnectionProcess do
  use Constructor

  @moduledoc """
  Connection process module model

  conn: save status connection
  params: tuple with the scheme, host and port
  conn_time: connection time
  request: save info with the request
  """

  constructor do
    field(:conn, String.t(), constructor: &is_string/1)
    field(:params, :tuple, constructor: &is_tuple/1)
    field(:conn_time, :integer, constructor: &is_integer/1)
    field(:request, :maps, constructor: &is_map/1)
  end
end
