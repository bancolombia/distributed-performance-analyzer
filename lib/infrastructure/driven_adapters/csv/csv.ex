defmodule MyParser do
  def parse_stream(_enum, _opts), do: nil
end

defmodule DistributedPerformanceAnalyzer.Infrastructure.Adapters.Csv do
  @moduledoc """
  Provides functions for your csv dataset
  """

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

  @spec save_csv(any(), String.t(), String.t(), boolean()) :: {:ok}
  def save_csv(data, file_name, header, print) do
    if print do
      IO.puts("\n####CSV#####")
      IO.puts(header)
    end

    rows =
      data
      |> Stream.map(fn row ->
        if print do
          IO.puts(row)
        end

        row <> "\n"
      end)

    [header <> "\n"]
    |> Stream.concat(rows)
    |> Stream.into(File.stream!(file_name))
    |> Stream.run()
  end
end
