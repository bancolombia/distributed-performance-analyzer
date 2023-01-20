defmodule DistributedPerformanceAnalyzer.Domain.Model.LoadProcess do
  @moduledoc """
  TODO Steps orchestration
  """
  alias DistributedPerformanceAnalyzer.Domain.Model.StepModel

  @enforce_keys [:request, :step_name, :end_time]

  defstruct [:request, :step_name, :end_time]

  def new(%StepModel{duration: duration, request: request, name: name}) do
    %__MODULE__{
      request: request,
      step_name: name,
      end_time: :erlang.system_time(:milli_seconds) + duration
    }
  end
end
