defmodule DistributedPerformanceAnalyzer.Test.BenchmarkTest do
  use ExUnit.Case, async: false

  alias DistributedPerformanceAnalyzer.Utils.EtsServer

  @min_value 0
  @max_value 1_000_000

  setup_all do
    EtsServer.start() |> IO.inspect()
    :ok
  end

  @tag timeout: :infinity
  test "write benchmark", _ do
    Benchee.run(
      %{
        "ets" => fn -> EtsServer.write_random_item(:ets, @min_value, @max_value) end,
        "dets" => fn -> EtsServer.write_random_item(:dets, @min_value, @max_value) end,
        "mnesia_transaction" => fn ->
          EtsServer.write_random_item(:mnesia, @min_value, @max_value)
        end,
        "mnesia_dirty" => fn ->
          EtsServer.write_random_item(:mnesia_dirty, @min_value, @max_value)
        end,
        "mnesia_disk_transaction" => fn ->
          EtsServer.write_random_item(:mnesia_disk, @min_value, @max_value)
        end,
        "mnesia_disk_dirty" => fn ->
          EtsServer.write_random_item(:mnesia_disk_dirty, @min_value, @max_value)
        end
      },
      warmup: 1,
      time: 5,
      memory_time: 2,
      reduction_time: 2,
      formatters: [
        {Benchee.Formatters.HTML, file: "benchmarks/output/write_benchmark.html"},
        Benchee.Formatters.Console
      ]
    )
  end

  @tag timeout: :infinity
  test "read benchmark", _ do
    Benchee.run(
      %{
        "ets" => fn -> EtsServer.read_random_item(:ets, @min_value, @max_value) end,
        "dets" => fn -> EtsServer.read_random_item(:dets, @min_value, @max_value) end,
        "mnesia_transaction" => fn ->
          EtsServer.read_random_item(:mnesia, @min_value, @max_value)
        end,
        "mnesia_dirty" => fn ->
          EtsServer.read_random_item(:mnesia_dirty, @min_value, @max_value)
        end,
        "mnesia_disk_transaction" => fn ->
          EtsServer.read_random_item(:mnesia_disk, @min_value, @max_value)
        end,
        "mnesia_disk_dirty" => fn ->
          EtsServer.read_random_item(:mnesia_disk_dirty, @min_value, @max_value)
        end
      },
      warmup: 1,
      time: 5,
      memory_time: 2,
      reduction_time: 2,
      formatters: [
        {Benchee.Formatters.HTML, file: "benchmarks/output/read_benchmark.html"},
        Benchee.Formatters.Console
      ]
    )
  end
end
