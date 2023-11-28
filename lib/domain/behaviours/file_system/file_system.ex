defmodule DistributedPerformanceAnalyzer.Domain.Behaviours.FileSystem do
  @moduledoc """
  Definitions of operations on filesystem
  """

  @callback file_exists?(path :: term) :: boolean
  @callback has_valid_extension?(path :: term, extensions :: term) :: boolean
  @callback has_utf8_encoding?(path :: term) :: boolean
end
