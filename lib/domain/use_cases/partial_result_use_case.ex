defmodule DistributedPerformanceAnalyzer.Domain.UseCase.PartialResultUseCase do
  @moduledoc """
  TODO Partial Result use case
  """
  alias DistributedPerformanceAnalyzer.Domain.Model.PartialResult

  @spec combine(PartialResult.t(), PartialResult.t()) ::
          {:ok, PartialResult.t()} | {:error, atom()}
  def combine(partial0, partial1) do
    {:ok, partial} =
      PartialResult.new(
        success_count: partial0.success_count + partial1.success_count,
        redirect_count: partial0.redirect_count + partial1.redirect_count,
        bad_request_count: partial0.bad_request_count + partial1.bad_request_count,
        server_error_count: partial0.server_error_count + partial1.server_error_count,
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

    partial
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
            | success_count: partial.success_count + 1,
              success_mean_latency: partial.success_mean_latency + elapsed,
              success_max_latency: max(elapsed, partial.success_max_latency),
              times: [elapsed | partial.times]
          }

        :redirect ->
          %{partial | redirect_count: partial.redirect_count + 1}

        :bad_request ->
          %{partial | bad_request_count: partial.bad_request_count + 1}

        :server_error ->
          %{partial | server_error_count: partial.server_error_count + 1}

        :fail_http ->
          %{partial | fail_http_count: partial.fail_http_count + 1}
      end,
      request_result,
      keep_responses
    )
  end

  defp calculate(partial, {_time, {reason, _detail}}, _keep_responses) do
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
      | http_count: partial.http_count + 1,
        total_count: partial.total_count + 1,
        http_mean_latency: partial.http_mean_latency + elapsed,
        http_max_latency: max(elapsed, partial.http_max_latency),
        requests: combine_requests(request_result, partial.requests, keep_responses)
    }
  end

  defp add_failed_request(partial) do
    %{
      partial
      | total_count: partial.total_count + 1
    }
  end

  defp combine_requests(current, to_add, true), do: [current | to_add]
  defp combine_requests(_current, _to_add, _), do: []
end
