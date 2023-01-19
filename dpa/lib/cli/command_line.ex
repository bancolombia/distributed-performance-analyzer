defmodule Cli.CommandLine do
  @moduledoc false
  def main(_args) do
    Perf.Execution.launch_execution()
    Process.monitor(Process.whereis(Perf.MetricsAnalyzer))
    receive do
      {:DOWN, _ref, :process, _pid, :normal} -> IO.puts "Finishing...";
    end
  end
end
