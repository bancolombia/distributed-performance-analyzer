defmodule DistributedPerformanceAnalyzer.Test.ReportUseCaseIncrementalTest do
  use ExUnit.Case, async: false

  alias DistributedPerformanceAnalyzer.Domain.UseCase.Reports.ReportUseCase
  alias DistributedPerformanceAnalyzer.Domain.Model.PartialResult

  @path_csv_report "config/result.csv"
  @path_report_jmeter "config/jmeter.csv"
  @csv_header "concurrency, throughput, min latency (ms), mean latency (ms), max latency (ms), p90 latency (ms), p95 latency (ms), p99 latency (ms), http_mean_latency, http_max_latency, 2xx requests, 3xx requests, 4xx requests, 5xx requests, http_errors, protocol_errors, invocation_errors, nil_connection_errors, connection_errors, total_errors, total_requests"
  @jmeter_header "timeStamp,elapsed,label,responseCode,responseMessage,threadName,dataType,success,failureMessage,bytes,sentBytes,grpThreads,allThreads,URL,Latency,IdleTime,Connect"

  setup do
    # Backup existing files
    result_backup = backup_file(@path_csv_report)
    jmeter_backup = backup_file(@path_report_jmeter)

    Application.put_env(:distributed_performance_analyzer, :jmeter_report, true)
    Application.put_env(:distributed_performance_analyzer, :dpa_resume_step, 0)

    on_exit(fn ->
      restore_file(@path_csv_report, result_backup)
      restore_file(@path_report_jmeter, jmeter_backup)
    end)

    :ok
  end

  defp backup_file(path) do
    case File.read(path) do
      {:ok, content} -> content
      _ -> nil
    end
  end

  defp restore_file(path, nil), do: File.rm(path)
  defp restore_file(path, content), do: File.write!(path, content)

  defp build_partial(concurrency) do
    {:ok, partial} =
      PartialResult.new(
        concurrency: concurrency,
        throughput: 100,
        min_latency: 10,
        avg_latency: 50,
        max_latency: 200,
        p90_latency: 150,
        p95_latency: 170,
        p99_latency: 190,
        http_avg_latency: 55,
        http_max_latency: 210,
        success_count: 900,
        redirect_count: 5,
        bad_request_count: 3,
        server_error_count: 2,
        http_error_count: 10,
        protocol_error_count: 0,
        invocation_error_count: 0,
        nil_conn_count: 0,
        error_conn_count: 0,
        error_count: 10,
        total_count: 1000,
        requests: []
      )

    partial
  end

  # ── init_report_files/0 ──────────────────────────────────────────────

  describe "init_report_files/0" do
    test "creates result.csv with header" do
      File.rm(@path_csv_report)
      assert :ok = ReportUseCase.init_report_files()
      assert File.exists?(@path_csv_report)

      content = File.read!(@path_csv_report)
      assert String.starts_with?(content, @csv_header)
    end

    test "creates jmeter.csv with header when jmeter_report is true" do
      File.rm(@path_report_jmeter)
      Application.put_env(:distributed_performance_analyzer, :jmeter_report, true)

      assert :ok = ReportUseCase.init_report_files()
      assert File.exists?(@path_report_jmeter)

      content = File.read!(@path_report_jmeter)
      assert String.starts_with?(content, @jmeter_header)
    end

    test "overwrites existing result.csv" do
      File.write!(@path_csv_report, "old data\n")
      ReportUseCase.init_report_files()

      content = File.read!(@path_csv_report)
      refute String.contains?(content, "old data")
      assert String.starts_with?(content, @csv_header)
    end
  end

  # ── count_completed_steps/0 ──────────────────────────────────────────

  describe "count_completed_steps/0" do
    test "returns 0 when file does not exist" do
      File.rm(@path_csv_report)
      assert ReportUseCase.count_completed_steps() == 0
    end

    test "returns 0 when file has only header" do
      File.write!(@path_csv_report, @csv_header <> "\n")
      assert ReportUseCase.count_completed_steps() == 0
    end

    test "returns correct count with data rows" do
      rows =
        @csv_header <>
          "\n" <>
          "10, 100, 10, 50, 200, 150, 170, 190, 55, 210, 900, 5, 3, 2, 10, 0, 0, 0, 0, 10, 1000\n" <>
          "20, 200, 12, 55, 220, 160, 180, 195, 60, 230, 1800, 10, 6, 4, 20, 0, 0, 0, 0, 20, 2000\n"

      File.write!(@path_csv_report, rows)
      assert ReportUseCase.count_completed_steps() == 2
    end

    test "returns correct count with trailing newlines" do
      rows =
        @csv_header <>
          "\n" <>
          "10, 100, 10, 50, 200, 150, 170, 190, 55, 210, 900, 5, 3, 2, 10, 0, 0, 0, 0, 10, 1000\n" <>
          "\n\n"

      File.write!(@path_csv_report, rows)
      assert ReportUseCase.count_completed_steps() == 1
    end
  end

  # ── flush_step/1 ─────────────────────────────────────────────────────

  describe "flush_step/1" do
    test "appends a row to result.csv" do
      ReportUseCase.init_report_files()
      partial = build_partial(10)

      assert :ok = ReportUseCase.flush_step(partial)

      content = File.read!(@path_csv_report)
      lines = content |> String.split("\n") |> Enum.filter(&(&1 != ""))
      # header + 1 data row
      assert length(lines) == 2
      assert String.contains?(Enum.at(lines, 1), "10, 100, 10, 50")
    end

    test "appends multiple steps incrementally" do
      ReportUseCase.init_report_files()

      ReportUseCase.flush_step(build_partial(10))
      ReportUseCase.flush_step(build_partial(20))
      ReportUseCase.flush_step(build_partial(30))

      content = File.read!(@path_csv_report)
      lines = content |> String.split("\n") |> Enum.filter(&(&1 != ""))
      # header + 3 data rows
      assert length(lines) == 4
    end

    test "preserves existing data on append" do
      ReportUseCase.init_report_files()
      ReportUseCase.flush_step(build_partial(10))

      content_before = File.read!(@path_csv_report)
      ReportUseCase.flush_step(build_partial(20))
      content_after = File.read!(@path_csv_report)

      assert String.starts_with?(content_after, content_before)
    end
  end
end
