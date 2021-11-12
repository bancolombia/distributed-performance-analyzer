defmodule StepModel do
  @enforce_keys ~w[
    request
    name
    step_number
    duration
    concurrency
    dataset]a

  defstruct ~w[
    request
    name
    step_number
    duration
    concurrency
    dataset]a

  def new(model = %ExecutionModel{increment: increment, constant_load: false}, step_num) when step_num > 0 do
    new(model, step_num, step_num * increment)
  end

  def new(model = %ExecutionModel{increment: increment, constant_load: true}, step_num) when step_num > 0 do
    new(model, step_num, increment)
  end

  # TODO: Implement new step model for csv data

  defp new(%ExecutionModel{request: request, duration: duration, dataset: dataset}, step_num, concurrency) do
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
