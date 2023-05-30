defmodule DistributedPerformanceAnalyzer.Test.LoadStepTest do
  use ExUnit.Case
  doctest DistributedPerformanceAnalyzer.Domain.UseCase.LoadStepUseCase

  test "should generate load" do
    # Perf.ConnectionPool.ensure_capacity(10)
    # Process.register(self(), :collector_test_2)
    # conf = Perf.LoadGenerator.Conf.new("GET", "/rest/appInfo/version")
    # Perf.LoadStep.start_step({conf, "Step-1", 1000, 10, Perf.LoadStepTest.CollectorMock})
    #
    # 1..10 |> Enum.each(fn _ ->
    #  receive do
    #    {a, c} -> IO.puts(inspect(a))
    #  end
    # end)
  end

  defmodule CollectorMock do
    def send_metrics(results, step) do
      send(:collector_test_2, {step, results})
    end
  end
end
