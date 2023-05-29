defmodule MyParser do
  def parse_stream(_enum, _opts), do: nil
end

defmodule DistributedPerformanceAnalyzer.Infrastructure.Adapters.Csv.Csv do
  @moduledoc """
  Provides functions for your csv dataset
  """
  alias DistributedPerformanceAnalyzer.Domain.Behaviours.DataSetBehaviour

  @behaviour DataSetBehaviour

  @file_system_behaviour Application.compile_env(
                           :distributed_performance_analyzer,
                           :file_system_behaviour
                         )

  require Logger

  @spec parse_csv(String.t(), String.t()) :: {:ok, list}
  def parse_csv(path, separator) do
    NimbleCSV.define(MyParser, separator: separator, escape: "\'")
    IO.puts("Reading Dataset: #{path}")

    if !File.exists?(path) do
      Logger.warn("File not found: #{path}\n")
    end

    {_status, file_size} = FileSize.from_file(path)
    IO.puts("File Size: #{file_size}\n")

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

  def report_csv(data, file, header, print, fun) do
    {:ok, file} = File.open(file, [:write])

    if print do
      IO.puts("####CSV#######")
      IO.puts(header)
    end

    IO.binwrite(file, header <> "\n")

    Enum.each(
      data,
      fn item ->
        row = fun.(item)
        IO.binwrite(file, row <> "\n")

        if print do
          IO.puts(row)
        end
      end
    )
  end
end
