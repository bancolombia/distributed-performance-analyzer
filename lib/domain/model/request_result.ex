defmodule DistributedPerformanceAnalyzer.Domain.Model.RequestResult do
  @moduledoc """
  TODO Result of a single request
  """
  alias DistributedPerformanceAnalyzer.Domain.Model.RequestResult

  defstruct start: 0,
            time_stamp: 0,
            label: "",
            thread_name: "",
            grp_threads: 0,
            all_threads: 0,
            url: "",
            elapsed: 0,
            response_code: 0,
            response_message: "",
            data_type: "",
            success: false,
            failure_message: "",
            bytes: 0,
            sent_bytes: 0,
            latency: 0,
            idle_time: 0,
            connect: 0,
            response_headers: []

  def new(label, thread_name, url, sent_bytes, connect) do
    %__MODULE__{
      start: :erlang.monotonic_time(:millisecond),
      time_stamp: System.os_time(:millisecond),
      label: label,
      thread_name: thread_name,
      url: url,
      sent_bytes: sent_bytes,
      connect: connect
    }
  end

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
