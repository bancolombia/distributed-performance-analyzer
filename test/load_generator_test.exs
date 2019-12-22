
defmodule Perf.LoadGeneratorTest do
  use ExUnit.Case
  doctest Perf.LoadGenerator


  test "should generate load" do
    Perf.ConnectionPool.ensure_capacity(1)

    conf = Perf.LoadGenerator.Conf.new("GET", "/")
    time = :erlang.monotonic_time(:milli_seconds) + 4000
    {:ok, _} = Perf.LoadGenerator.start_link({conf, "Step1", time, Perf.LoadGeneratorTest.CollectorMock})

    Process.register(self(), :collector_test)

    receive do
      {c, d} -> IO.puts("#{c}: #{Enum.count(d)}")
    end

  end


  defmodule CollectorMock do
    def send_metrics(results, step) do
      send(:collector_test, {step, results})
    end
  end

end


