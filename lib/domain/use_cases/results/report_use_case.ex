defmodule DistributedPerformanceAnalyzer.Domain.UseCase.Results.ReportUseCase do
  alias DistributedPerformanceAnalyzer.Domain.Model.RequestResult
  alias DistributedPerformanceAnalyzer.Domain.UseCase.MetricsAnalyzerUseCase
  alias DistributedPerformanceAnalyzer.Infrastructure.Adapters.Csv.Csv

  use Task

  def init(map_results, sorted_curve) do
    if Application.get_env(:perf_analyzer, :jmeter_report, true) do
      tasks = [
        Task.async(fn -> generate_jmeter_report(sorted_curve) end),
        Task.async(fn -> report_result_csv(map_results) end)
      ]

      Task.await_many(tasks)
    else
      report_result_csv(map_results)
    end
  end

  def report_result_csv(map_results) do
    report(
      map_results,
      "config/result.csv",
      "concurrency, throughput, mean latency, p90 latency, max latency",
      true,
      fn {concurrency, throughput, lat_total, p90, max_latency, _mean_latency_http,
          _fail_http_count, _protocol_error_count, _error_conn_count, _nil_conn_count} ->
        "#{concurrency}, #{round(throughput)}, #{lat_total}, #{p90}, #{max_latency}"
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
      "config/jmeter.csv",
      "timeStamp,elapsed,label,responseCode,responseMessage,threadName,dataType,success,failureMessage,bytes,sentBytes,grpThreads,allThreads,URL,Latency,IdleTime,Connect",
      false,
      fn %RequestResult{
           start: start,
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
    format = String.split(file, ".", parts: 2) |> Enum.at(1)

    case format do
      "csv" ->
        Csv.report_csv(data, file, header, print, fun)
        # "txt" ->
    end
  end
end
