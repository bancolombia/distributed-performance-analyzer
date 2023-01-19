
defmodule Perf.LoadGeneratorTest do
  use ExUnit.Case
  doctest Perf.LoadGenerator


  test "should generate load" do
    #Perf.ConnectionPool.ensure_capacity(1)
    #Process.sleep(600)
    #conf = Perf.LoadGenerator.Conf.new("GET", "/api/admin/apps/10000")
    #time = :erlang.monotonic_time(:milli_seconds) + 1000
    #{:ok, _} = Perf.LoadGenerator.start_link({conf, "Step1", time, Perf.LoadGeneratorTest.CollectorMock})
    #
    #Process.register(self(), :collector_test)
    #
    #receive do
    #  {c, results} ->
    #    IO.puts("#{c}: #{Enum.count(results)}")
    #end

  end


  defmodule CollectorMock do
    def send_metrics(results, step) do
      send(:collector_test, {step, results})
    end
  end

end


