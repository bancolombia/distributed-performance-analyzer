defmodule DistributedPerformanceAnalyzer.Domain.UseCase.RequestResultUseCase do
  @moduledoc """
  TODO Updates usecase description
  """
  alias DistributedPerformanceAnalyzer.Domain.Model.RequestResult

  ## TODO Add functions to business logic app
  def complete(
        %RequestResult{start: start} = initial,
        response_code,
        body,
        response_headers,
        latency
      ) do
    elapsed = :erlang.monotonic_time(:milli_seconds) - start

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
