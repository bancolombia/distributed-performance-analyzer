defmodule MyParser do
  def parse_stream(_enum, _opts), do: nil
end

defmodule DistributedPerformanceAnalyzer.Infrastructure.Adapters.Csv.Csv do
  @moduledoc """
  Provides functions for your csv dataset
  """
  alias DistributedPerformanceAnalyzer.Domain.Behaviours.DataSetBehaviour

  @behaviour DataSetBehaviour

  require Logger

  @spec load(String.t(), map()) :: {:ok, list}
  def load(path, %{type: type, separator: separator}) do
    NimbleCSV.define(MyParser, separator: separator, escape: "\'")
    IO.puts("Reading #{type} Dataset: #{path}")

    if !File.exists?(path) do
      Logger.warn("File not found: #{path}\n")
    end

    {_status, file_size} = FileSize.from_file(path)
    IO.puts("File Size: #{file_size}\n")

    data_stream =
      File.stream!(path)
      |> MyParser.parse_stream(skip_headers: false)

    headers =
      Stream.drop(data_stream, -1)
      |> Enum.to_list()
      |> Enum.at(0)
      |> Enum.map(&String.to_atom/1)

    result =
      Stream.drop(data_stream, 1)
      |> Stream.map(fn item ->
        Enum.zip(headers, item) |> Enum.into(%{})
      end)
      |> Enum.to_list()

    {:ok, result}
  end

  def load(_path, _args) do
    {:error, "the dataset type and separator are required"}
  end
end
