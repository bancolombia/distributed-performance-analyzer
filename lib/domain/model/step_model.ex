defmodule DistributedPerformanceAnalyzer.Domain.Model.StepModel do
  @moduledoc """
  TODO Model for a step
  """
  alias DistributedPerformanceAnalyzer.Domain.Model.ExecutionModel

  @enforce_keys [
    :request,
    :name,
    :step_number,
    :duration,
    :concurrency,
    :dataset
  ]

  defstruct [
    :request,
    :name,
    :step_number,
    :duration,
    :concurrency,
    :dataset
  ]

  def new(model = %ExecutionModel{increment: increment, constant_load: false}, step_num)
      when step_num > 0 do
    new(model, step_num, step_num * increment)
  end

  def new(model = %ExecutionModel{increment: increment, constant_load: true}, step_num)
      when step_num > 0 do
    new(model, step_num, increment)
  end

  defp new(
         %ExecutionModel{request: request, duration: duration, dataset: dataset},
         step_num,
         concurrency
       ) do
    %__MODULE__{
      request: request,
      name: "Step-#{step_num}",
      step_number: step_num,
      duration: duration,
      concurrency: concurrency,
      dataset: dataset
    }
  end
end
