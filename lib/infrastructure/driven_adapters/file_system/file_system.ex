defmodule DistributedPerformanceAnalyzer.Infrastructure.Adapters.FileSystem do
  require Logger

  @moduledoc """
  Provides functions for handle file system operations
  """

  @spec file_exists?(String.t()) :: boolean
  def file_exists?(path), do: File.exists?(path)

  @spec has_valid_extension?(String.t(), List.t()) :: boolean
  def has_valid_extension?(path, extensions) do
    ext = Path.extname(path) |> String.downcase()
    Enum.map(extensions, &String.downcase/1) |> Enum.member?(ext)
  end

  @spec has_utf8_encoding?(String.t()) :: boolean
  def has_utf8_encoding?(path) do
    case File.read(path) do
      {:ok, content} ->
        String.valid?(content)

      {:error, reason} ->
        Logger.error("Error reading file: #{inspect(reason)}")
        false
    end
  end

  def print_file_info(path) do
    %{size: size} = File.stat!(path)
    Logger.info("File size: #{size}B\n")
  end
end
