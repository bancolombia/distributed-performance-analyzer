defmodule DistributedPerformanceAnalyzer.Domain.Model.LoadProcess do
  @moduledoc """
  TODO Steps orchestration
  """
  alias DistributedPerformanceAnalyzer.Domain.Model.Step

  @enforce_keys [:request, :step_name, :end_time]

  @allowed_keys ["request", "step_name", "end_time"]

  @type t :: %__MODULE__{
          request: Request.t(),
          step_name: String.t(),
          end_time: float()
        }

  defstruct [:request, :step_name, :end_time]

  @spec new(Step.t()) :: LoadProcess.t()
  def new(%Step{execution_model: execution_model, name: name}) do
    %__MODULE__{
      request: execution_model.request,
      step_name: name,
      end_time: :erlang.system_time(:milli_seconds) + execution_model.duration
    }
  end
end
