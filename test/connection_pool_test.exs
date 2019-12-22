defmodule Perf.ConnectionPoolTest do
  use ExUnit.Case
  doctest Perf.ConnectionPool

  test "pool test size" do
    Process.exit(Process.whereis(Perf.ConnectionPool), :kill)
    Process.sleep(200)
    Perf.ConnectionPool.ensure_capacity(1)

    conn = Perf.ConnectionPool.get_connection()
    assert conn != nil

    conn = Perf.ConnectionPool.get_connection()
    assert conn == nil
  end



end
