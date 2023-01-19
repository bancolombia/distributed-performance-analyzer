defmodule ExecutionModel do
  defstruct [:request, :steps, :increment, :duration, :dataset, :separator, constant_load: false]
end
