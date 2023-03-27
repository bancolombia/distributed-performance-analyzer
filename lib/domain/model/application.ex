defmodule DistributedPerformanceAnalyzer.Domain.Model.Application do

  @moduledoc """
  Application module model.

  host: part of the url
  path: part of the url
  scheme: represents HTTP or HTTPS protocols
  port: port of the request
  query: query of the url (part of the url that goes after the ampersand ?)
  url: full url
  connection_conf: scheme, host, port, united
  distributed: distributed test (boolean)
  method: http method used by the request
  headers: request headers
  body: body of the request
  execution_conf: structure in which all the fields of the request travel
  children: node for distributed load
  connection_conf: tuple with the fields of schema, hots and port of the request
  """

   #TODO: check scope of created variables
   @enforce_keys[:host, :path, :scheme, :port, :query, :url,
                 :connection_conf, :distributed,
                 :method, :headers, :body,
                 :execution_conf,
                 :children, :connection_conf]
   @allowed_keys["host", "path", "scheme", "port", "query",
                 "connection_conf", "distributed",
                 "method", "headers", "body",
                 "execution_conf",
                 "children", "connection_conf"]

  defstruct [:host, :path, :scheme, :port, :query, :url,
  :connection_conf, :distributed,
  :method, :headers, :body,
  :execution_conf,
  :children, :connection_conf
  ]

  #def new() do
  #  %__MODULE__{}
  #end

end
