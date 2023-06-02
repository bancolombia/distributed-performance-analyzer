defmodule DistributedPerformanceAnalyzer.Infrastructure.Adapters.FileSystem.Parser do
  require Logger
  alias DistributedPerformanceAnalyzer.Infrastructure.Adapters.{Csv, FileSystem}

  @moduledoc """
  Provides functions for handle file parsers
  """

  @spec file_exists?(String.t()) :: boolean
  def file_exists?(path), do: FileSystem.path_exists?(path)

  @spec parse_csv(String.t(), String.t()) :: {:ok, list}
  def parse_csv(path, separator) do
    print_file_info(path)
    Csv.read_csv(path, separator)
  end

  defp print_file_info(path) do
    Logger.info("Reading Dataset: #{path}")
    %{size: size} = FileSystem.get_file_stat(path)
    Logger.info("File Size: #{size}B\n")
  end
end
