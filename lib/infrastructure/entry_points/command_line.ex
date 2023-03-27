defmodule DistributedPerformanceAnalyzer.Infrastructure.EntryPoint.CommandLine do
  @moduledoc """
  Command Line
  """
  alias DistributedPerformanceAnalyzer.Domain.UseCase.ExecutionUseCase

  def main(_args) do
    # execution pending migration
    ExecutionUseCase.launch_execution()
    Process.monitor(Process.whereis(Perf.MetricsAnalyzer))

    receive do
      {:DOWN, _ref, :process, _pid, :normal} -> IO.puts("Finishing...")
    end
  end
end
