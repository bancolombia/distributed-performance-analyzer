defmodule MyParser do
  def parse_stream(_enum, _opts), do: nil
end

defmodule DistributedPerformanceAnalyzer.Infrastructure.Adapters.Csv do
  @moduledoc """
  Provides functions for your csv dataset
  """

  @behaviour DataSetBehaviour

  require Logger

  def read_csv(path, separator) do
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
