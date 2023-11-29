defmodule DistributedPerformanceAnalyzer.Domain.Behaviours.FileSystem do
  @moduledoc """
  Definitions of operations on filesystem
  """

  @type path :: String.t()
  @type extensions :: [String.t()]

  @callback file_exists?(path) :: boolean
  @callback has_valid_extension?(path, extensions) :: boolean
  @callback has_utf8_encoding?(path) :: boolean
end
