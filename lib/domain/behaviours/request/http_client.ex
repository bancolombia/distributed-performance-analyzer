defmodule DistributedPerformanceAnalyzer.Domain.Behaviours.Request.HttpClient do
  @moduledoc """
  Definitions of operations for HTTP client
  """

  alias DistributedPerformanceAnalyzer.Domain.Model.{Config.Request, Config.Response}

  @type connection :: any()
  @type response :: Response.t()
  @type reason :: String.t()
  @type request_conf :: Request.t()

  @callback open_connection(request_conf) :: {:ok, connection} | {:error, reason}
  @callback close_connection(connection) :: :ok
  @callback do_request(connection, request_conf) :: {:ok, response} | {:error, reason}
end
