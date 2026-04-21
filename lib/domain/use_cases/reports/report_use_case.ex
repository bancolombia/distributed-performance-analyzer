defmodule DistributedPerformanceAnalyzer.Domain.UseCase.Reports.ReportUseCase do
  @moduledoc """
  Use case report

  the report use case is called by all modules that need
  to print information to outgoing files or logs
  """

  alias DistributedPerformanceAnalyzer.Domain.Model.{RequestResult, PartialResult}
  alias DistributedPerformanceAnalyzer.Domain.UseCase.MetricsAnalyzerUseCase
  alias DistributedPerformanceAnalyzer.Utils.DataTypeUtils

  use Task
  require Logger

  @report_csv Application.compile_env(
                :distributed_performance_analyzer,
                :report_exporter
              )

  @valid_extensions ["csv"]
  @path_report_jmeter "config/jmeter.csv"
  @path_csv_report "config/result.csv"

  @csv_result_header "concurrency, throughput, min latency (ms), mean latency (ms), max latency (ms), p90 latency (ms), p95 latency (ms), p99 latency (ms), http_mean_latency, http_max_latency, 2xx requests, 3xx requests, 4xx requests, 5xx requests, http_errors, protocol_errors, invocation_errors, nil_connection_errors, connection_errors, total_errors, total_requests"
  @jmeter_header "timeStamp,elapsed,label,responseCode,responseMessage,threadName,dataType,success,failureMessage,bytes,sentBytes,grpThreads,allThreads,URL,Latency,IdleTime,Connect"

  # ------------------------------------------------------------------
  # Initialization helpers
  # ------------------------------------------------------------------

  @doc """
  Creates the output CSV files with their headers, overwriting any
  previous content.  Must be called once at the beginning of a fresh
  (non-resumed) execution so that `flush_step/1` can safely append.
  """
  def init_report_files() do
    File.write!(@path_csv_report, @csv_result_header <> "\n")

    if Application.get_env(:distributed_performance_analyzer, :jmeter_report, true) do
      File.write!(@path_report_jmeter, @jmeter_header <> "\n")
    end

    :ok
  end

  @doc """
  Returns the number of completed step rows already written to result.csv.
  Used by `ExecutionUseCase` to detect a previous partial run and resume
  from the correct step instead of starting over.
  """
  def count_completed_steps() do
    case File.read(@path_csv_report) do
      {:ok, content} ->
        content
        |> String.split("\n")
        |> Enum.filter(&(&1 != "" and not String.starts_with?(&1, "concurrency")))
        |> length()

      _ ->
        0
    end
  end

  @doc """
  Immediately appends the consolidated metrics for a completed step to both
  result.csv and jmeter.csv (append mode).  Called by `MetricsCollectorUseCase`
  right after each step finishes so that data is durable even if the
  container is killed before the final report is generated.
  """
  def flush_step(%PartialResult{} = partial) do
    row = format_result_row(partial)
    File.write!(@path_csv_report, row <> "\n", [:append, :utf8])

    if Application.get_env(:distributed_performance_analyzer, :jmeter_report, true) do
      flush_jmeter_rows(partial.requests)
    end

    :ok
  end

  # ------------------------------------------------------------------
  # Final report generation
  # ------------------------------------------------------------------

  def init(sorted_curve, total_data) do
    start = DataTypeUtils.start_time()
    Logger.info("Generating report...")

    resume_step = Application.get_env(:distributed_performance_analyzer, :dpa_resume_step, 0)
    is_resumed = resume_step > 0

    resume_total_data(total_data)

    if is_resumed do
      # All data was already written incrementally via flush_step/1.
      # Only sort jmeter.csv in-place so the final file is timestamp-ordered.
      if Application.get_env(:distributed_performance_analyzer, :jmeter_report, true) do
        sort_jmeter_report_file()
      end
    else
      if Application.get_env(:distributed_performance_analyzer, :jmeter_report, true) do
        tasks = [
          Task.async(fn -> generate_jmeter_report(sorted_curve) end),
          Task.async(fn -> generate_csv_report(sorted_curve) end)
        ]

        Task.await_many(tasks, :infinity)
      else
        generate_csv_report(sorted_curve)
      end
    end

    Logger.info("Report generated in #{DataTypeUtils.duration_time(start)}ms...")
  end

  def resume_total_data([steps_count, total_success_count, total_error_count, total_duration]) do
    ~s(
    Total success requests count: #{total_success_count}
    Total failed requests count: #{total_error_count}
    Total steps: #{steps_count}
    Total duration: #{total_duration} seconds\n)
    |> IO.puts()
  end

  def generate_csv_report(sorted_curve) do
    sorted_curve
    |> Enum.map(
      &"#{&1.concurrency}, #{&1.throughput}, #{&1.min_latency}, #{&1.avg_latency}, #{&1.max_latency}, #{&1.p90_latency}, #{&1.p95_latency}, #{&1.p99_latency}, #{&1.http_avg_latency}, #{&1.http_max_latency}, #{&1.success_count}, #{&1.redirect_count}, #{&1.bad_request_count}, #{&1.server_error_count}, #{&1.http_error_count}, #{&1.protocol_error_count}, #{&1.invocation_error_count}, #{&1.nil_conn_count},  #{&1.error_conn_count}, #{&1.error_count}, #{&1.total_count}"
    )
    |> export_report(
      @path_csv_report,
      "concurrency, throughput, min latency (ms), mean latency (ms), max latency (ms), p90 latency (ms), p95 latency (ms), p99 latency (ms), http_mean_latency, http_max_latency, 2xx requests, 3xx requests, 4xx requests, 5xx requests, http_errors, protocol_errors, invocation_errors, nil_connection_errors, connection_errors, total_errors, total_requests",
      true
    )
  end

  def generate_jmeter_report(sorted_curve) do
    sorted_curve
    |> Enum.reduce([], &Enum.concat(&1.requests, &2))
    |> Enum.sort(fn req_a, req_b -> req_a.time_stamp < req_b.time_stamp end)
    |> Enum.map(fn %RequestResult{
                     start: _start,
                     time_stamp: time_stamp,
                     label: label,
                     thread_name: thread_name,
                     grp_threads: grp_threads,
                     all_threads: all_threads,
                     url: url,
                     elapsed: elapsed,
                     response_code: response_code,
                     failure_message: failure_message,
                     sent_bytes: sent_bytes,
                     latency: latency,
                     idle_time: idle_time,
                     connect: connect,
                     received_bytes: received_bytes,
                     content_type: content_type
                   } ->
      "#{time_stamp},#{elapsed},#{label},#{response_code},#{MetricsAnalyzerUseCase.response_for_code(response_code)},#{thread_name},#{content_type},#{MetricsAnalyzerUseCase.success?(response_code)},#{MetricsAnalyzerUseCase.with_failure(response_code, failure_message)},#{received_bytes},#{sent_bytes},#{grp_threads},#{all_threads},#{url},#{latency},#{idle_time},#{connect}"
    end)
    |> export_report(
      @path_report_jmeter,
      "timeStamp,elapsed,label,responseCode,responseMessage,threadName,dataType,success,failureMessage,bytes,sentBytes,grpThreads,allThreads,URL,Latency,IdleTime,Connect",
      false
    )
  end

  def export_report(data, file, header, print) do
    start = DataTypeUtils.start_time()
    report_format = String.ends_with?(file, Enum.at(@valid_extensions, 0))

    case report_format do
      true ->
        @report_csv.save_csv(data, file, header, print)

      false ->
        {:error, "invalid report extensions type"}
    end

    Logger.info("#{file} exported in #{DataTypeUtils.duration_time(start)}ms...")
  end

  # ------------------------------------------------------------------
  # Private helpers for incremental (per-step) writes
  # ------------------------------------------------------------------

  defp format_result_row(p) do
    "#{p.concurrency}, #{p.throughput}, #{p.min_latency}, #{p.avg_latency}, #{p.max_latency}, #{p.p90_latency}, #{p.p95_latency}, #{p.p99_latency}, #{p.http_avg_latency}, #{p.http_max_latency}, #{p.success_count}, #{p.redirect_count}, #{p.bad_request_count}, #{p.server_error_count}, #{p.http_error_count}, #{p.protocol_error_count}, #{p.invocation_error_count}, #{p.nil_conn_count},  #{p.error_conn_count}, #{p.error_count}, #{p.total_count}"
  end

  defp flush_jmeter_rows([]), do: :ok

  defp flush_jmeter_rows(requests) do
    rows = requests |> Enum.map(&format_jmeter_row/1) |> Enum.join("\n")
    File.write!(@path_report_jmeter, rows <> "\n", [:append, :utf8])
  end

  defp format_jmeter_row(%RequestResult{
         time_stamp: time_stamp,
         label: label,
         thread_name: thread_name,
         grp_threads: grp_threads,
         all_threads: all_threads,
         url: url,
         elapsed: elapsed,
         response_code: response_code,
         failure_message: failure_message,
         sent_bytes: sent_bytes,
         latency: latency,
         idle_time: idle_time,
         connect: connect,
         received_bytes: received_bytes,
         content_type: content_type
       }) do
    "#{time_stamp},#{elapsed},#{label},#{response_code},#{MetricsAnalyzerUseCase.response_for_code(response_code)},#{thread_name},#{content_type},#{MetricsAnalyzerUseCase.success?(response_code)},#{MetricsAnalyzerUseCase.with_failure(response_code, failure_message)},#{received_bytes},#{sent_bytes},#{grp_threads},#{all_threads},#{url},#{latency},#{idle_time},#{connect}"
  end

  # Reads the existing jmeter.csv written incrementally, sorts all data
  # rows by timestamp (first column), and rewrites the file in-place.
  # Used during a resumed execution to produce a clean final output.
  defp sort_jmeter_report_file() do
    case File.read(@path_report_jmeter) do
      {:ok, content} when content != "" ->
        lines = content |> String.split("\n") |> Enum.filter(&(&1 != ""))

        case lines do
          [] ->
            :ok

          [_header_only] ->
            :ok

          [header | rows] ->
            sorted =
              Enum.sort_by(rows, fn row ->
                case row |> String.split(",", parts: 2) |> List.first("0") |> Integer.parse() do
                  {ts, _} -> ts
                  :error -> 0
                end
              end)

            File.write!(@path_report_jmeter, Enum.join([header | sorted], "\n") <> "\n")
        end

      _ ->
        :ok
    end
  end
end
