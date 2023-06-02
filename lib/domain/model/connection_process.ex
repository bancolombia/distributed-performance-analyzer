defmodule DistributedPerformanceAnalyzer.Domain.Model.ConnectionProcess do
  @moduledoc """
  Connection process module model

  conn: save status connection
  params: tuple with the scheme, host and port
  conn_time: connection time
  request: save info with the request
  """

  #  @enforce_keys [:conn, :params, :conn_time, :request]

  @allowed_keys ["conn", "params", "conn_time", "request"]

  # TODO: review params y conn types
  @type t :: %__MODULE__{
          conn: String.t(),
          params: {},
          conn_time: integer(),
          request: %{}
        }

  defstruct [:conn, :params, :conn_time, request: %{}]

  # def new() do
  #  %__MODULE__{}
  # end
end
