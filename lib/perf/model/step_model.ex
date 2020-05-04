defmodule StepModel do
  @enforce_keys ~w[
    request
    name
    step_number
    duration
    concurrency]a

  defstruct ~w[
    request
    name
    step_number
    duration
    concurrency]a

  def new(%ExecutionModel{request: request, duration: duration, increment: increment}, step_num) when step_num > 0 do
    %__MODULE__{
      request: request,
      name: "Step-#{step_num}",
      step_number: step_num,
      duration: duration,
      concurrency: step_num * increment,
    }
  end

end
