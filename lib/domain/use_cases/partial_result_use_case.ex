defmodule DistributedPerformanceAnalyzer.Domain.UseCase.PartialResultUseCase do
  @moduledoc """
  TODO Partial Result use case
  """
  alias DistributedPerformanceAnalyzer.Domain.Model.PartialResult

  @spec combine(PartialResult.t(), PartialResult.t()) ::
          {:ok, PartialResult.t()} | {:error, atom()}
  def combine(partial0, partial1) do
    PartialResult.new(
      success_count: partial0.success_count + partial1.success_count,
      http_count: partial0.http_count + partial1.http_count,
      total_count: partial0.total_count + partial1.total_count,
      fail_http_count: partial0.fail_http_count + partial1.fail_http_count,
      protocol_error_count: partial0.protocol_error_count + partial1.protocol_error_count,
      invocation_error_count: partial0.invocation_error_count + partial1.invocation_error_count,
      error_conn_count: partial0.error_conn_count + partial1.error_conn_count,
      nil_conn_count: partial0.nil_conn_count + partial1.nil_conn_count,
      success_mean_latency: partial0.success_mean_latency + partial1.success_mean_latency,
      http_mean_latency: partial0.http_mean_latency + partial1.http_mean_latency,
      http_max_latency: max(partial0.http_max_latency, partial1.http_max_latency),
      success_max_latency: max(partial0.success_max_latency, partial1.success_max_latency),
      concurrency: partial0.concurrency + partial1.concurrency,
      times: Enum.concat(partial0.times, partial1.times),
      requests: Enum.concat(partial0.requests, partial1.requests)
    )
  end

  def calculate(result_list, opts) do
    Enum.reduce(result_list, PartialResult.new(concurrency: 1), fn item, acc ->
      calculate(acc, item, opts[:keep_responses])
    end)
  end

  defp calculate(partial, {_time, {:ok, %{elapsed: elapsed} = request_result}}, keep_responses) do
    %{
      partial
      | success_count: partial.success_count + 1,
        http_count: partial.http_count + 1,
        total_count: partial.total_count + 1,
        success_mean_latency: partial.success_mean_latency + elapsed,
        http_mean_latency: partial.http_mean_latency + elapsed,
        success_max_latency: max(elapsed, partial.success_max_latency),
        http_max_latency: max(elapsed, partial.http_max_latency),
        times: [elapsed | partial.times],
        requests: combine_requests(request_result, partial.requests, keep_responses)
    }
  end

  defp calculate(partial, {0, :invocation_error}, _) do
    %{
      partial
      | total_count: partial.total_count + 1,
        invocation_error_count: partial.invocation_error_count + 1
    }
  end

  defp calculate(partial, {_time, {:nil_conn, _reason}}, _keep_responses) do
    %{partial | total_count: partial.total_count + 1, nil_conn_count: partial.nil_conn_count + 1}
  end

  defp calculate(partial, {_time, {:error_conn, _reason}}, _keep_responses) do
    %{
      partial
      | total_count: partial.total_count + 1,
        error_conn_count: partial.error_conn_count + 1
    }
  end

  defp calculate(partial, {_time, {:protocol_error, _reason}}, _keep_responses) do
    %{
      partial
      | total_count: partial.total_count + 1,
        protocol_error_count: partial.protocol_error_count + 1
    }
  end

  defp calculate(
         partial,
         {_time, {{:fail_http, _status_code}, %{elapsed: elapsed} = request_result}},
         keep_responses
       ) do
    %{
      partial
      | total_count: partial.total_count + 1,
        http_count: partial.http_count + 1,
        fail_http_count: partial.fail_http_count + 1,
        http_mean_latency: partial.http_mean_latency + elapsed,
        http_max_latency: max(elapsed, partial.http_max_latency),
        requests: combine_requests(request_result, partial.requests, keep_responses)
    }
  end

  defp combine_requests(current, to_add, true), do: [current | to_add]
  defp combine_requests(_current, _to_add, _), do: []

  def calculate_p90(partial) do
    case Enum.count(partial.times) do
      0 ->
        partial

      _ ->
        sorted_times = Enum.sort(partial.times)
        n = length(sorted_times)
        index = 0.90 * n

        p90_calc =
          case is_round?(index) do
            true ->
              x = Enum.at(sorted_times, trunc(index))
              xp = Enum.at(sorted_times, trunc(index) + 1)

              ((x + xp) / 2)
              |> IO.inspect()
              |> round

            false ->
              index = round(index)
              Enum.at(sorted_times, index)
          end
          |> round

        %{partial | p90: p90_calc, times: []}
    end
  end

  defp is_round?(n) do
    Float.floor(n) == n
  end
end
