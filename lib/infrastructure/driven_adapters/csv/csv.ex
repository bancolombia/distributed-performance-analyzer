defmodule MyParser do
  def parse_stream(_enum, _opts), do: nil
end

defmodule DistributedPerformanceAnalyzer.Infrastructure.Adapters.Csv do
  @moduledoc """
  Provides functions for your csv operations
  """
  require Logger

  alias DistributedPerformanceAnalyzer.Domain.Behaviours.{Dataset.DatasetParser, Reports.Report}
  alias DistributedPerformanceAnalyzer.Infrastructure.Adapters.FileSystem

  @behaviour DatasetParser
  @behaviour Report

  @impl DatasetParser
  @spec parse_csv(path :: String.t(), separator :: String.t()) ::
          {:ok, result :: List.t()} | {:error, reason :: String.t()}
  def parse_csv(path, separator) do
    FileSystem.print_file_info(path)
    NimbleCSV.define(MyParser, separator: separator, escape: "\'")

    data_stream =
      File.stream!(path, [{:encoding, :utf8}, :trim_bom])
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

  @impl Report
  @spec save_csv(
          data :: String.t(),
          file_name :: String.t(),
          header :: String.t(),
          print :: boolean()
        ) :: {:ok, result :: term} | {:error, reason :: String.t()}
  def save_csv(data, file_name, header, print) do
    if print do
      IO.puts("\n####CSV#####")
      IO.puts(header)
    end

    rows = data |> Stream.map(&format_row(&1, print))

    [header <> "\n"]
    |> Stream.concat(rows)
    |> Stream.into(File.stream!(file_name))
    |> Stream.run()
  end

  defp format_row(row, print?) do
    if print?, do: IO.puts(row)
    row <> "\n"
  end
end
