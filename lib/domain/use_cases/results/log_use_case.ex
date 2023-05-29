defmodule DistributedPerformanceAnalyzer.Domain.UseCase.Results.LogUseCase do
  alias DistributedPerformanceAnalyzer.Domain.UseCase.Results.ReportUseCase

  def init(steps_count, total_success_count, total_duration, sorted_curve) do
    total_data(steps_count, total_success_count, total_duration)
    map_results = items_map(sorted_curve)
    format_dpa(map_results)
    {:ok, map_results}
  end

  def total_data(steps_count, total_success_count, total_duration) do
    ~s(Total success count: #{total_success_count}\nTotal steps: #{steps_count}\nTotal duration: #{total_duration} seconds)
    |> IO.puts()
  end

  def items_map(sorted_curve) do
    Enum.map(
      sorted_curve,
      fn {_step, throughput, concurrency, lat_total, max_latency, mean_latency_http, partial} ->
        {concurrency, throughput, round(lat_total), partial.p90, round(max_latency),
         round(mean_latency_http), partial.fail_http_count, partial.protocol_error_count,
         partial.error_conn_count, partial.nil_conn_count}
      end
    )
  end

  def format_dpa(map) do
    IO.puts(
      "concurrency, throughput -- mean latency, p90 latency, max latency, mean http latency, http_errors, protocol_error_count, error_conn_count, nil_conn_count"
    )

    Enum.each(
      map,
      fn {concurrency, throughput, lat_total, p90, max_latency, mean_latency_http,
          fail_http_count, protocol_error_count, error_conn_count, nil_conn_count} ->
        IO.puts(
          "#{concurrency}, #{throughput}, -- #{lat_total}, #{p90}ms, #{max_latency}ms, #{mean_latency_http}ms, #{fail_http_count}, #{protocol_error_count}, #{error_conn_count}, #{nil_conn_count}"
        )
      end
    )
  end

  def format_results_step(concurrency, partial, mean_latency) do
    IO.puts(
      "#{concurrency}, #{partial.success_count} -- #{round(mean_latency)}ms, #{partial.p90}ms, #{partial.fail_http_count}, #{partial.protocol_error_count}, #{partial.error_conn_count}, #{partial.nil_conn_count}"
    )
  end
end
