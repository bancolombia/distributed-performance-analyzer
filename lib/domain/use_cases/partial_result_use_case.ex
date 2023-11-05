defmodule DistributedPerformanceAnalyzer.Domain.UseCase.PartialResultUseCase do
  @moduledoc """
  TODO Partial Result use case
  """
  alias DistributedPerformanceAnalyzer.Domain.Model.PartialResult
  alias DistributedPerformanceAnalyzer.Utils.{Statistics, DataTypeUtils}

  require Logger

  @spec combine(PartialResult.t(), PartialResult.t()) ::
          {:ok, PartialResult.t()} | {:error, atom()}
  def combine(partial0, partial1) do
    {:ok, partial} =
      PartialResult.new(
        redirect_count: partial0.redirect_count + partial1.redirect_count,
        bad_request_count: partial0.bad_request_count + partial1.bad_request_count,
        server_error_count: partial0.server_error_count + partial1.server_error_count,
        fail_http_count: partial0.fail_http_count + partial1.fail_http_count,
        protocol_error_count: partial0.protocol_error_count + partial1.protocol_error_count,
        invocation_error_count: partial0.invocation_error_count + partial1.invocation_error_count,
        error_conn_count: partial0.error_conn_count + partial1.error_conn_count,
        nil_conn_count: partial0.nil_conn_count + partial1.nil_conn_count,
        total_count: partial0.total_count + partial1.total_count,
        concurrency: partial0.concurrency + partial1.concurrency,
        times: Enum.concat(partial0.times, partial1.times),
        success_times: Enum.concat(partial0.success_times, partial1.success_times),
        requests: Enum.concat(partial0.requests, partial1.requests)
      )

    partial
  end

  def consolidate(
        %PartialResult{
          success_times: success_times,
          times: times,
          error_count: error_count,
          total_count: total_count
        } =
          partial,
        duration
      ) do
    success_count = length(success_times)
    p90 = Statistics.percentile(success_times, 90) || 0
    p95 = Statistics.percentile(success_times, 95) || 0
    p99 = Statistics.percentile(success_times, 99) || 0
    min = Statistics.min(success_times) || 0
    max = Statistics.max(success_times) || 0
    avg = Statistics.mean(success_times) || 0
    throughput = Statistics.throughput(success_count, duration) || 0
    http_avg = Statistics.mean(times) || 0
    http_max = Statistics.max(times) || 0

    http_error_count =
      partial.redirect_count + partial.bad_request_count + partial.server_error_count +
        partial.fail_http_count

    error_count =
      if total_count > success_count + error_count,
        do: total_count - success_count,
        else: error_count

    %{
      partial
      | success_count: success_count,
        p90_latency: p90 |> DataTypeUtils.round_number(2),
        p95_latency: p95 |> DataTypeUtils.round_number(2),
        p99_latency: p99 |> DataTypeUtils.round_number(2),
        min_latency: min |> DataTypeUtils.round_number(2),
        max_latency: max |> DataTypeUtils.round_number(2),
        avg_latency: avg |> DataTypeUtils.round_number(2),
        http_error_count: http_error_count,
        error_count: error_count,
        http_avg_latency: http_avg |> DataTypeUtils.round_number(2),
        http_max_latency: http_max |> DataTypeUtils.round_number(2),
        throughput: throughput |> DataTypeUtils.round_number(2),
        times: [],
        success_times: []
    }
  end

  def print_status(%PartialResult{
        concurrency: concurrency,
        throughput: throughput,
        min_latency: min,
        avg_latency: avg,
        max_latency: max,
        p90_latency: p90,
        success_count: status_200,
        bad_request_count: status_400,
        server_error_count: status_500,
        error_count: errors,
        total_count: total
      }) do
    IO.puts(
      "Concurrency -> users: #{concurrency} - tps: #{throughput} | Latency -> min: #{min}ms - avg: #{avg}ms - max: #{max}ms - p90: #{p90}ms | Requests -> 2xx: #{status_200} - 4xx: #{status_400} - 5xx: #{status_500} | total_errors: #{errors} - total_request: #{total}"
    )
  end

  def calculate(result_list, opts) do
    {:ok, partial} = PartialResult.new(concurrency: 1)

    Enum.reduce(result_list, partial, fn item, acc ->
      calculate(acc, item, opts[:keep_responses])
    end)
  end

  defp calculate(partial, {_time, {status, %{elapsed: elapsed} = request_result}}, keep_responses) do
    add_success_request(
      case status do
        :ok ->
          %{
            partial
            | success_times: [elapsed | partial.success_times]
          }

        :redirect ->
          %{partial | redirect_count: partial.redirect_count + 1}

        :bad_request ->
          %{partial | bad_request_count: partial.bad_request_count + 1}

        :server_error ->
          %{partial | server_error_count: partial.server_error_count + 1}

        _ ->
          %{partial | fail_http_count: partial.fail_http_count + 1}
      end,
      request_result,
      keep_responses
    )
  end

  defp calculate(partial, {_time, {reason, detail}}, _keep_responses) do
    Logger.warning("Request error: #{reason}, #{detail}")

    add_failed_request(
      case reason do
        :invocation_error ->
          %{partial | invocation_error_count: partial.invocation_error_count + 1}

        :nil_conn ->
          %{partial | nil_conn_count: partial.nil_conn_count + 1}

        :error_conn ->
          %{partial | error_conn_count: partial.error_conn_count + 1}

        :protocol_error ->
          %{partial | protocol_error_count: partial.protocol_error_count + 1}

        _ ->
          %{partial | fail_http_count: partial.fail_http_count + 1}
      end
    )
  end

  defp add_success_request(
         partial,
         %{elapsed: elapsed} = request_result,
         keep_responses
       ) do
    %{
      partial
      | total_count: partial.total_count + 1,
        times: [elapsed | partial.times],
        requests: combine_requests(request_result, partial.requests, keep_responses)
    }
  end

  defp add_failed_request(partial) do
    %{
      partial
      | error_count: partial.error_count + 1,
        total_count: partial.total_count + 1
    }
  end

  defp combine_requests(current, to_add, true), do: [current | to_add]
  defp combine_requests(_current, _to_add, _), do: []
end
