defmodule DistributedPerformanceAnalyzer.Test.PartialResultDpaEventTest do
  use ExUnit.Case, async: true

  alias DistributedPerformanceAnalyzer.Domain.Model.PartialResult

  import ExUnit.CaptureIO
  import ExUnit.CaptureLog

  alias DistributedPerformanceAnalyzer.Domain.UseCase.PartialResultUseCase

  defp build_partial(overrides \\ []) do
    defaults = [
      concurrency: 10,
      throughput: 150,
      min_latency: 12,
      avg_latency: 45,
      max_latency: 230,
      p90_latency: 89,
      success_count: 1450,
      bad_request_count: 3,
      server_error_count: 0,
      nil_conn_count: 0,
      invocation_error_count: 0,
      protocol_error_count: 0,
      error_conn_count: 0,
      error_count: 3,
      total_count: 1453
    ]

    merged = Keyword.merge(defaults, overrides)
    {:ok, partial} = PartialResult.new(merged)
    partial
  end

  describe "print_status/1 emits DPA_EVENT" do
    test "outputs a DPA_EVENT line with valid JSON" do
      partial = build_partial()

      output = capture_io(fn -> PartialResultUseCase.print_status(partial) end)

      lines = output |> String.split("\n") |> Enum.filter(&String.starts_with?(&1, "DPA_EVENT"))
      assert length(lines) == 1

      [event_line] = lines
      json_str = String.replace_prefix(event_line, "DPA_EVENT ", "")
      assert {:ok, decoded} = Jason.decode(json_str)
      assert decoded["type"] == "step_complete"
    end

    test "DPA_EVENT contains all expected fields" do
      partial = build_partial()

      output = capture_io(fn -> PartialResultUseCase.print_status(partial) end)

      event_line =
        output
        |> String.split("\n")
        |> Enum.find(&String.starts_with?(&1, "DPA_EVENT"))

      json_str = String.replace_prefix(event_line, "DPA_EVENT ", "")
      {:ok, decoded} = Jason.decode(json_str)

      expected_keys = [
        "type",
        "concurrency",
        "throughput",
        "min_latency",
        "avg_latency",
        "max_latency",
        "p90_latency",
        "success_count",
        "bad_request_count",
        "server_error_count",
        "nil_conn_errors",
        "invocation_errors",
        "protocol_errors",
        "conn_errors",
        "error_count",
        "total_count"
      ]

      Enum.each(expected_keys, fn key ->
        assert Map.has_key?(decoded, key), "Missing key: #{key}"
      end)
    end

    test "DPA_EVENT values match partial result" do
      partial = build_partial(concurrency: 25, throughput: 300, min_latency: 5)

      output = capture_io(fn -> PartialResultUseCase.print_status(partial) end)

      event_line =
        output
        |> String.split("\n")
        |> Enum.find(&String.starts_with?(&1, "DPA_EVENT"))

      {:ok, decoded} = Jason.decode(String.replace_prefix(event_line, "DPA_EVENT ", ""))

      assert decoded["concurrency"] == 25
      assert decoded["throughput"] == 300
      assert decoded["min_latency"] == 5
    end

    test "also outputs the legacy Concurrency line" do
      partial = build_partial()

      output = capture_io(fn -> PartialResultUseCase.print_status(partial) end)

      assert output =~ "Concurrency -> users: 10"
      assert output =~ "tps: 150"
    end

    test "logs warnings for nil connection errors" do
      partial = build_partial(nil_conn_count: 5)

      log =
        capture_log(fn ->
          capture_io(fn -> PartialResultUseCase.print_status(partial) end)
        end)

      assert log =~ "nil connections errors"
    end
  end
end
