defmodule DistributedPerformanceAnalyzer.Test.Domain.UseCase.Reports.ReportsUseCaseTest do
  use ExUnit.Case, async: true

  alias DistributedPerformanceAnalyzer.Domain.UseCase.{
    Reports.ReportUseCase,
    MetricsAnalyzerUseCase
  }

  alias DistributedPerformanceAnalyzer.Domain.Model.{PartialResult, RequestResult}

  @report_csv Application.compile_env(
                :distributed_performance_analyzer,
                :report_csv
              )

  @data [
    {1, 6, 113, 102, 0},
    {2, 19, 101, 102, 0},
    {3, 29, 101, 102, 0},
    {4, 39, 101, 102, 0},
    {5, 48, 101, 102, 0}
  ]
  @sorted_curve [
    {
      5,
      48.333333333333336,
      5,
      101.79999297931083,
      103,
      101.79999297931083,
      %PartialResult{
        requests: [
          %RequestResult{
            start: -576_460_648_213,
            time_stamp: 1_685_668_282_444,
            label: "sample",
            thread_name: "#PID<0.602.0>",
            grp_threads: 0,
            all_threads: 0,
            url: "GET -> http://localhost:8080/wait/100",
            elapsed: 102,
            response_code: 200,
            response_message: "",
            data_type: "",
            success: false,
            failure_message: "OK After 100 milliseconds",
            bytes: 0,
            sent_bytes: 0,
            latency: 102,
            idle_time: 0,
            connect: 0,
            response_headers: [
              {"cache-control", "max-age=0, private, must-revalidate"},
              {"content-length", "25"},
              {"date", "Fri, 02 Jun 2023 01:11:20 GMT"},
              {"server", "Cowboy"}
            ]
          }
        ],
        p90: 102,
        p95: 103,
        p99: 103,
        times: [],
        concurrency: 4,
        success_max_latency: 103,
        http_max_latency: 103,
        http_mean_latency: 11_800,
        success_mean_latency: 11_800,
        nil_conn_count: 0,
        error_conn_count: 0,
        invocation_error_count: 0,
        protocol_error_count: 0,
        fail_http_count: 0,
        total_count: 116,
        http_count: 116,
        success_count: 116
      }
    }
  ]
  @header "concurrency, throughput, mean_latency, p90_latency, http_errors"
  @print true
  @file_csv "config/report.csv"

  test "successful transformation of the sorted_curve" do
    # Arrange
    # Act
    result = ReportUseCase.format_result(@sorted_curve)
    # Assert
    assert result ==
             {:ok, [{5, 48, 102, 102, 103, 103, 103, 102, 0, 0, 0, 0}]}
  end

  test "total data printing successful" do
    # Arrange
    total_data = [1, 2, 3]
    # Act
    result = ReportUseCase.resume_total_data(total_data)
    # Assert
    assert result ==
             ~s(Total success count: 1\nTotal steps: 2\nTotal duration: 3 seconds)
             |> IO.puts()
  end

  test "printing results per step successful" do
    # Arrange
    result_step = [
      5,
      %DistributedPerformanceAnalyzer.Domain.Model.PartialResult{
        requests: [
          %DistributedPerformanceAnalyzer.Domain.Model.RequestResult{
            start: -576_460_648_213,
            time_stamp: 1_685_668_282_444,
            label: "sample",
            thread_name: "#PID<0.602.0>",
            grp_threads: 0,
            all_threads: 0,
            url: "GET -> http://localhost:8080/wait/100",
            elapsed: 102,
            response_code: 200,
            response_message: "",
            data_type: "",
            success: false,
            failure_message: "OK After 100 milliseconds",
            bytes: 0,
            sent_bytes: 0,
            latency: 102,
            idle_time: 0,
            connect: 0,
            response_headers: [
              {"cache-control", "max-age=0, private, must-revalidate"},
              {"content-length", "25"},
              {"date", "Fri, 02 Jun 2023 01:11:20 GMT"},
              {"server", "Cowboy"}
            ]
          }
        ],
        p90: 102,
        times: [],
        concurrency: 4,
        success_max_latency: 103,
        http_max_latency: 103,
        http_mean_latency: 11_800,
        success_mean_latency: 11_800,
        nil_conn_count: 0,
        error_conn_count: 0,
        invocation_error_count: 0,
        protocol_error_count: 0,
        fail_http_count: 0,
        total_count: 116,
        http_count: 116,
        success_count: 116
      },
      10
    ]

    # Act
    result = ReportUseCase.log_step_result(result_step)
    # Assert
    assert result ==
             IO.puts("5, 116, 10ms, 102ms, 0, 0, 0, 0")
  end

  test "generate successful csv report in basic format" do
    # Arrange

    data = [
      {1, 6, 113, 102, 103, 103, 300, 113, 0, 0, 0, 0},
      {2, 19, 101, 102, 103, 103, 102, 101, 0, 0, 0, 0},
      {3, 29, 101, 102, 103, 103, 102, 101, 0, 0, 0, 0}
    ]

    # Act
    result = ReportUseCase.generate_csv_report(data)
    # Assert
    assert result ==
             ReportUseCase.report(
               data,
               @file_csv,
               "concurrency, throughput, mean latency (ms), p90 latency (ms), p95 latency (ms), p99 latency (ms), max latency (ms), mean http latency (ms), http_errors, protocol_error, error_conn, nil_conn",
               @print,
               fn {concurrency, throughput, lat_total, p90, p95, p99, max_latency,
                   mean_latency_http, fail_http_count, protocol_error_count, error_conn_count,
                   nil_conn_count} ->
                 "#{concurrency}, #{throughput}, #{lat_total}, #{p90}, #{p95}, #{p99}, #{max_latency}, #{mean_latency_http}, #{fail_http_count}, #{protocol_error_count}, #{error_conn_count}, #{nil_conn_count}"
               end
             )
  end

  test "generate successful csv report in jmeter format" do
    # Arrange
    data_jmeter_transformer = [
      %DistributedPerformanceAnalyzer.Domain.Model.RequestResult{
        start: -576_460_648_213,
        time_stamp: 1_685_668_282_444,
        label: "sample",
        thread_name: "#PID<0.602.0>",
        grp_threads: 0,
        all_threads: 0,
        url: "GET -> http://localhost:8080/wait/100",
        elapsed: 102,
        response_code: 200,
        response_message: "",
        data_type: "",
        success: false,
        failure_message: "OK After 100 milliseconds",
        bytes: 0,
        sent_bytes: 0,
        latency: 102,
        idle_time: 0,
        connect: 0,
        response_headers: [
          {"cache-control", "max-age=0, private, must-revalidate"},
          {"content-length", "25"},
          {"date", "Fri, 02 Jun 2023 01:11:20 GMT"},
          {"server", "Cowboy"}
        ]
      }
    ]

    # Act
    result = ReportUseCase.generate_jmeter_report(@sorted_curve)
    # Assert
    assert result ==
             ReportUseCase.report(
               data_jmeter_transformer,
               "config/jmeter.csv",
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

  test "invalid report extensions type" do
    #    Arrange
    file = "config/report.txt"

    # Act
    result =
      ReportUseCase.report(
        @data,
        file,
        @header,
        @print,
        fn {concurrency, throughput, lat_total, p90, http_errors} ->
          "#{concurrency}, #{throughput}, #{lat_total}, #{p90}, #{http_errors}"
        end
      )

    # Assert
    assert result == {:error, "invalid report extensions type"}
  end

  test "valid report extensions type" do
    #    Arrange

    # Act
    result =
      ReportUseCase.report(
        @data,
        @file_csv,
        @header,
        @print,
        fn {concurrency, throughput, lat_total, p90, http_errors} ->
          "#{concurrency}, #{throughput}, #{lat_total}, #{p90}, #{http_errors}"
        end
      )

    # Assert
    assert result ==
             @report_csv.save_csv(
               @data,
               @file_csv,
               @header,
               @print,
               fn {concurrency, throughput, lat_total, p90, http_errors} ->
                 "#{concurrency}, #{throughput}, #{lat_total}, #{p90}, #{http_errors}"
               end
             )
  end
end
