defmodule DistributedPerformanceAnalyzer.Domain.UseCase.ReportUseCase do
  @moduledoc """
  Use case report

  the report use case is called by all modules that need
  to print information to outgoing files or logs
  """
  use Task
  require Logger

  alias DistributedPerformanceAnalyzer.Config.AppConfig
  alias DistributedPerformanceAnalyzer.Domain.Model.RequestResult

  alias DistributedPerformanceAnalyzer.Domain.UseCase.{
    Config.ConfigUseCase,
    MetricsAnalyzerUseCase
  }

  alias DistributedPerformanceAnalyzer.Utils.DataTypeUtils

  @report_exporter Application.compile_env!(AppConfig.get_app_name(), :report_exporter)
  @valid_extensions ["csv"]
  @path_report_jmeter "config/jmeter.csv"
  @path_csv_report "config/result.csv"

  def init(sorted_curve, total_data) do
    start = DataTypeUtils.start_time()
    Logger.info("Generating report...")

    resume_total_data(total_data)

    if ConfigUseCase.get(:jmeter_report, true) do
      tasks = [
        Task.async(fn -> generate_jmeter_report(sorted_curve) end),
        Task.async(fn -> generate_csv_report(sorted_curve) end)
      ]

      Task.await_many(tasks, :infinity)
    else
      generate_csv_report(sorted_curve)
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
        @report_exporter.save_csv(data, file, header, print)

      false ->
        {:error, "invalid report extensions type"}
    end

    Logger.info("#{file} exported in #{DataTypeUtils.duration_time(start)}ms...")
  end
end
