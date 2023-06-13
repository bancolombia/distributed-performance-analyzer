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
        received_bytes,
        content_type,
        latency
      ) do
    elapsed = :erlang.monotonic_time(:milli_seconds) - start

    %{
      initial
      | elapsed: elapsed,
        latency: latency - start,
        response_code: response_code,
        failure_message: body,
        received_bytes: received_bytes,
        content_type: content_type
    }
  end
end
