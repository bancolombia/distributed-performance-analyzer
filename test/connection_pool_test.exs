defmodule DistributedPerformanceAnalyzer.Test.ConnectionPoolTest do
  use ExUnit.Case, async: true
  doctest DistributedPerformanceAnalyzer.Domain.UseCase.ConnectionPoolUseCase

  test "pool test size" do
    # Process.exit(Process.whereis(Perf.ConnectionPool), :kill)
    # Process.sleep(200)
    # Perf.ConnectionPool.ensure_capacity(1)
    #
    # conn = Perf.ConnectionPool.get_connection()
    # assert conn != nil
    #
    # conn = Perf.ConnectionPool.get_connection()
    # assert conn == nil
  end
end
