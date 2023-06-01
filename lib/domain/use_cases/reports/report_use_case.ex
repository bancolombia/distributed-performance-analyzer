defmodule DistributedPerformanceAnalyzer.Domain.UseCase.Reports.ReportUseCase do
  @moduledoc """
  Use case report

  the report use case is called by all modules that need
  to print information to outgoing files or logs
  """

  alias DistributedPerformanceAnalyzer.Domain.Model.RequestResult
  alias DistributedPerformanceAnalyzer.Domain.UseCase.MetricsAnalyzerUseCase

  use Task

  @report_csv Application.compile_env(
                :distributed_performance_analyzer,
                :report_csv
              )

  @valid_extensions ["csv"]
  @path_report_jmeter "config/jmeter.csv"
  @path_csv_report "config/report.csv"

  def init(sorted_curve, total_data) do
    {:ok, report} = format_result(sorted_curve)

    resume_total_data(total_data)

    if Application.get_env(:perf_analyzer, :jmeter_report, true) do
      tasks = [
        Task.async(fn -> generate_jmeter_report(sorted_curve) end),
        Task.async(fn -> generate_csv_report(report) end)
      ]

      Task.await_many(tasks)
    else
      generate_csv_report(report)
    end
  end

  def format_result(sorted_curve) do
    {:ok,
     Enum.map(
       sorted_curve,
       fn {_step, throughput, concurrency, lat_total, max_latency, mean_latency_http, partial} ->
         {concurrency, round(throughput), round(lat_total), partial.p90, round(max_latency),
          round(mean_latency_http), partial.fail_http_count, partial.protocol_error_count,
          partial.error_conn_count, partial.nil_conn_count}
       end
     )}
  end

  def resume_total_data(total_data) do
    total_success_count = Enum.at(total_data, 0)
    steps_count = Enum.at(total_data, 1)
    total_duration = Enum.at(total_data, 2)

    ~s(Total success count: #{total_success_count}\nTotal steps: #{steps_count}\nTotal duration: #{total_duration} seconds)
    |> IO.puts()
  end

  def results_step_log(result_step) do
    concurrency = Enum.at(result_step, 0)
    partial = Enum.at(result_step, 1)
    mean_latency = Enum.at(result_step, 2)

    IO.puts(
      "#{concurrency}, #{partial.success_count}, #{round(mean_latency)}ms, #{partial.p90}ms, #{partial.fail_http_count}, #{partial.protocol_error_count}, #{partial.error_conn_count}, #{partial.nil_conn_count}"
    )
  end

  def generate_csv_report(result) do
    report(
      result,
      @path_csv_report,
      "concurrency, throughput, mean latency, p90 latency in ms, max latency in ms, mean http latency in ms, http_errors, protocol_error_count, error_conn_count, nil_conn_count",
      true,
      fn {concurrency, throughput, lat_total, p90, max_latency, mean_latency_http,
          fail_http_count, protocol_error_count, error_conn_count, nil_conn_count} ->
        "#{concurrency}, #{throughput}, #{lat_total}, #{p90}, #{max_latency}, #{mean_latency_http}, #{fail_http_count}, #{protocol_error_count}, #{error_conn_count}, #{nil_conn_count}"
      end
    )
  end

  def generate_jmeter_report(sorted_curve) do
    request_details =
      Enum.reduce(
        sorted_curve,
        [],
        fn {_, _, _, _, _, _, %{requests: list}}, current -> Enum.concat(list, current) end
      )
      |> Enum.sort(fn req_a, req_b -> req_a.time_stamp < req_b.time_stamp end)

    report(
      request_details,
      @path_report_jmeter,
      "timeStamp,elapsed,label,responseCode,responseMessage,threadName,dataType,success,failureMessage,bytes,sentBytes,grpThreads,allThreads,URL,Latency,IdleTime,Connect",
      false,
      fn %RequestResult{
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
           response_headers: headers
         } ->
        "#{time_stamp},#{elapsed},#{label},#{response_code},#{MetricsAnalyzerUseCase.response_for_code(response_code)},#{thread_name},#{MetricsAnalyzerUseCase.data_type(headers)},#{MetricsAnalyzerUseCase.success?(response_code)},#{MetricsAnalyzerUseCase.with_failure(response_code, failure_message)},#{MetricsAnalyzerUseCase.bytes(headers)},#{sent_bytes},#{grp_threads},#{all_threads},#{url},#{latency},#{idle_time},#{connect}"
      end
    )
  end

  defp report(data, file, header, print, fun) do
    report_format = String.ends_with?(file, Enum.at(@valid_extensions, 0))

    case report_format do
      true ->
        @report_csv.save_csv(data, file, header, print, fun)
    end
  end
end
