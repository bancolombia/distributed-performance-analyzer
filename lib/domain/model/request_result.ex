defmodule DistributedPerformanceAnalyzer.Domain.Model.RequestResult do
  @moduledoc """
  TODO Result of a single request
  """

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

  def new() do
    %__MODULE__{}
  end
end
