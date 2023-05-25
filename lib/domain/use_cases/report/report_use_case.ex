defmodule DistributedPerformanceAnalyzer.Domain.UseCase.Report.ReportUseCase do
  alias DistributedPerformanceAnalyzer.Domain.Model.RequestResult
  alias DistributedPerformanceAnalyzer.Domain.UseCase.MetricsAnalyzerUseCase

  @file_system_behaviour Application.compile_env(
                           :distributed_performance_analyzer,
                           :file_system_behaviour
                         )

  def total_data(steps_count, total_success_count, total_duration) do
    ~s(Total success count: #{total_success_count}\nTotal steps: #{steps_count}\nTotal duration: #{total_duration} seconds)
    |> IO.puts()
  end

  def report_dpa(sorted_curve) do
    IO.puts(
      "concurrency, throughput -- mean latency, p90 latency, max latency, mean http latency, http_errors, protocol_error_count, error_conn_count, nil_conn_count"
    )

    Enum.each(
      sorted_curve,
      fn {_step, throughput, concurrency, lat_total, max_latency, mean_latency_http, partial} ->
        IO.puts(
          "#{concurrency}, #{throughput} -- #{round(lat_total)}ms, #{partial.p90}ms, #{round(max_latency)}ms, #{round(mean_latency_http)}ms, #{partial.fail_http_count}, #{partial.protocol_error_count}, #{partial.error_conn_count}, #{partial.nil_conn_count}"
        )
      end
    )
  end

  def report_result_csv(sorted_curve) do
    write_to_file(
      sorted_curve,
      "config/result.csv",
      "concurrency, throughput, mean latency, p90 latency, max latency",
      true,
      fn {_step, throughput, concurrency, lat_total, max_latency, _mean_latency_http, partial} ->
        "#{concurrency}, #{round(throughput)}, #{round(lat_total)}, #{partial.p90}, #{round(max_latency)}"
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

    write_to_file(
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

  def report_results(concurrency, partial, mean_latency) do
    IO.puts(
      "#{concurrency}, #{partial.success_count} -- #{round(mean_latency)}ms, #{partial.p90}ms, #{partial.fail_http_count}, #{partial.protocol_error_count}, #{partial.error_conn_count}, #{partial.nil_conn_count}"
    )
  end

  defp write_to_file(data, file, header, print, fun) do
    {:ok, file} = File.open(file, [:write])

    if print do
      IO.puts("####CSV#######")
      IO.puts(header)
    end

    IO.binwrite(file, header <> "\n")

    Enum.each(
      data,
      fn item ->
        row = fun.(item)
        IO.binwrite(file, row <> "\n")

        if print do
          IO.puts(row)
        end
      end
    )
  end
end
