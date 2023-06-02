defmodule DistributedPerformanceAnalyzer.Infrastructure.Adapters.OutputCsv do
  @moduledoc """
  Print outgoing report file in csv format
  """

  @spec save_csv(any(), String.t(), String.t(), boolean(), any()) :: {:ok}
  def save_csv(data, file, header, print, fun) do
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
