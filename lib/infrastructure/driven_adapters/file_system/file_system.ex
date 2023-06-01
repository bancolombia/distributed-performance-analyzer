defmodule DistributedPerformanceAnalyzer.Infrastructure.Adapters.FileSystem do
  @moduledoc """
  DA to perform operations on the system file system
  """

  def path_exists?(path) do
    File.exists?(path)
  end

  def get_file_stat(path) do
    File.stat!(path)
  end
end
