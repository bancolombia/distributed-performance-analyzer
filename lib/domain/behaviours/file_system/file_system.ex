defmodule DistributedPerformanceAnalyzer.Domain.Behaviours.FileSystem do
  @moduledoc """
  Definitions of operations on filesystem
  """

  @type path :: String.t()
  @type extensions :: [String.t()]

  @callback file_exists?(path) :: boolean
  @callback valid_extension?(path, extensions) :: boolean
  @callback utf8_encoding?(path) :: boolean
end
