defmodule DistributedPerformanceAnalyzer.Domain.Behaviours.User.HttpClient do
  @moduledoc """
  Definitions of operations for http client
  """

  @type endpoint :: String.t()
  @type pool_size :: integer
  @type params :: List.t()
  @type response :: String.t()
  @type reason :: String.t()

  @callback start_client() :: {:ok, pid} | {:error, reason}
  @callback start_connection(endpoint, pool_size) :: {:ok, pid} | {:error, reason}
  @callback send_request(endpoint, params) :: {:ok, response} | {:error, reason}
end
