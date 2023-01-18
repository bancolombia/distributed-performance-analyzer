defmodule DistributedPerformanceAnalyzer.Domain.Model.LoadProcess do
  @moduledoc """
  TODO Steps orchestration
  """
  alias DistributedPerformanceAnalyzer.Domain.Model.Step

  @enforce_keys ~w[
    request
    step_name
    end_time]a

  defstruct ~w[
    request
    step_name
    end_time]a

  def new(%Step{duration: duration, request: request, name: name}) do
    %__MODULE__{
      request: request,
      step_name: name,
      end_time: :erlang.system_time(:milli_seconds) + duration
    }
  end
end
