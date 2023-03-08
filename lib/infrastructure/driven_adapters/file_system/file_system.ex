defmodule DistributedPerformanceAnalyzer.Infrastructure.Adapters.FileSystem.FileSystem do
  @moduledoc """
  DA to perform operations on the system file system
  """
  alias DistributedPerformanceAnalyzer.Domain.Behaviours.FileSystemBehaviour

  @behaviour FileSystemBehaviour

  @spec write_to_file(any(), String.t(), String.t(), boolean(), any()) :: {:ok}
  def write_to_file(data, file, header, print, fun) do
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
