defmodule DistributedPerformanceAnalyzer.Infrastructure.Adapters.FileSystem do
  require Logger

  alias DistributedPerformanceAnalyzer.Domain.Behaviours.FileSystem

  @behaviour FileSystem

  @moduledoc """
  Provides functions for handle file system operations
  """

  @impl FileSystem
  @spec file_exists?(path :: String.t()) :: boolean
  def file_exists?(path), do: File.exists?(path)

  @impl FileSystem
  @spec valid_extension?(path :: String.t(), extensions :: [String.t()]) :: boolean
  def valid_extension?(path, extensions) do
    ext = Path.extname(path) |> String.downcase()
    Enum.map(extensions, &String.downcase/1) |> Enum.member?(ext)
  end

  @impl FileSystem
  @spec utf8_encoding?(path :: String.t()) :: boolean
  def utf8_encoding?(path) do
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
