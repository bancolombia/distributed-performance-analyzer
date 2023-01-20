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
end
