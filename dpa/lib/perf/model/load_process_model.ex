defmodule LoadProcessModel do
  @enforce_keys ~w[
    request
    step_name
    end_time]a

  defstruct ~w[
    request
    step_name
    end_time]a

  def new(%StepModel{duration: duration, request: request, name: name}) do
    %__MODULE__{
      request: request,
      step_name: name,
      end_time: :erlang.system_time(:milli_seconds) + duration,
    }
  end

end
