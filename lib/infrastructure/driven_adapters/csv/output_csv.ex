defmodule DistributedPerformanceAnalyzer.Infrastructure.Adapters.OutputCsv do
  @moduledoc """
  Print outgoing report file in csv format
  """
  require Logger

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
