defmodule DistributedPerformanceAnalyzer.Test.Domain.UseCase.Reports.ReportsUseCaseTest do
  use ExUnit.Case, async: true

  alias DistributedPerformanceAnalyzer.Domain.UseCase.Reports.ReportUseCase

  @report_csv Application.compile_env(
                :distributed_performance_analyzer,
                :report_csv
              )

  @data [
    {1, 6, 113, 102, 300, 113, 0, 0, 0, 0},
    {2, 19, 101, 102, 102, 101, 0, 0, 0, 0},
    {3, 29, 101, 102, 102, 101, 0, 0, 0, 0},
    {4, 39, 101, 102, 103, 101, 0, 0, 0, 0},
    {5, 48, 101, 102, 102, 101, 0, 0, 0, 0}
  ]

  test "invalid report extensions type" do
    #    Arrange
    file = "config/report.txt"

    header =
      "concurrency, throughput, mean latency, p90 latency in ms, max latency in ms, mean http latency in ms, http_errors, protocol_error_count, error_conn_count, nil_conn_count"

    print = true

    # Act
    result =
      ReportUseCase.report(
        @data,
        file,
        header,
        print,
        fn {concurrency, throughput, lat_total, p90, max_latency, mean_latency_http,
            fail_http_count, protocol_error_count, error_conn_count, nil_conn_count} ->
          "#{concurrency}, #{throughput}, #{lat_total}, #{p90}, #{max_latency}, #{mean_latency_http}, #{fail_http_count}, #{protocol_error_count}, #{error_conn_count}, #{nil_conn_count}"
        end
      )

    # Assert
    assert result == {:error, "invalid report extensions type"}
  end

  test "valid report extensions type" do
    #    Arrange
    file = "config/report.csv"

    header =
      "concurrency, throughput, mean latency, p90 latency in ms, max latency in ms, mean http latency in ms, http_errors, protocol_error_count, error_conn_count, nil_conn_count"

    print = true

    # Act
    result =
      ReportUseCase.report(
        @data,
        file,
        header,
        print,
        fn {concurrency, throughput, lat_total, p90, max_latency, mean_latency_http,
            fail_http_count, protocol_error_count, error_conn_count, nil_conn_count} ->
          "#{concurrency}, #{throughput}, #{lat_total}, #{p90}, #{max_latency}, #{mean_latency_http}, #{fail_http_count}, #{protocol_error_count}, #{error_conn_count}, #{nil_conn_count}"
        end
      )

    # Assert
    assert result ==
             @report_csv.save_csv(
               @data,
               file,
               header,
               print,
               fn {concurrency, throughput, lat_total, p90, max_latency, mean_latency_http,
                   fail_http_count, protocol_error_count, error_conn_count, nil_conn_count} ->
                 "#{concurrency}, #{throughput}, #{lat_total}, #{p90}, #{max_latency}, #{mean_latency_http}, #{fail_http_count}, #{protocol_error_count}, #{error_conn_count}, #{nil_conn_count}"
               end
             )
  end
end
