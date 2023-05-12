defmodule DistributedPerformanceAnalyzer.Domain.Model.StepModel do
  @moduledoc """
  TODO Model for a step
  """
  alias DistributedPerformanceAnalyzer.Domain.Model.ExecutionModel

  @enforce_keys [
    :execution_model,
    :name,
    :step_number,
    :concurrency
  ]

  @allowed_keys ["execution_model", "name", "step_number", "concurrency"]

  @type t :: %__MODULE__{
          execution_model: ExecutionModel.t(),
          name: String.t(),
          step_number: integer(),
          concurrency: integer()
        }

  defstruct [
    :execution_model,
    :name,
    :step_number,
    :concurrency
  ]

  @spec new(ExecutionModel.t(), integer()) :: StepModel.t()
  def new(model = %ExecutionModel{increment: increment, constant_load: false}, step_num)
      when step_num > 0 do
    new(model, step_num, step_num * increment)
  end

  def new(model = %ExecutionModel{increment: increment, constant_load: true}, step_num)
      when step_num > 0 do
    new(model, step_num, increment)
  end

  defp new(model, step_num, concurrency) do
    %__MODULE__{
      execution_model: model,
      name: "Step-#{step_num}",
      step_number: step_num,
      concurrency: concurrency
    }
  end
end
