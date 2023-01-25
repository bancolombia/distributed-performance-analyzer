defmodule DistributedPerformanceAnalyzer.Domain.UseCase.RequestResultUseCase do
  @moduledoc """
  RequestResult use case
  """

  alias DistributedPerformanceAnalyzer.Domain.Model.RequestResult

  @spec complete(RequestResult.t(), integer(), String.t(), list(), number()) :: RequestResult.t()
  def complete(
        %RequestResult{start: start} = initial,
        response_code,
        body,
        response_headers,
        latency
      ) do
    elapsed = :erlang.monotonic_time(:millisecond) - start

    %{
      initial
      | elapsed: elapsed,
        latency: latency - start,
        response_code: response_code,
        failure_message: body,
        response_headers: response_headers
    }
  end
end
