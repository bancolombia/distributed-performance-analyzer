defmodule Perf.ExecutionTest do
  use ExUnit.Case
  doctest Perf.Execution

  test "test execution" do
    request = Perf.LoadGenerator.Conf.new("GET", "/rest/appInfo/version")
    conf = %Perf.Execution{request: request, steps: 5, increment: 10, duration: 700, collector: Perf.MetricsCollector}
    Perf.Execution.start(conf)
  end

end
