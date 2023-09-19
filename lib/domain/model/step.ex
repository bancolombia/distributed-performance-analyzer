defmodule DistributedPerformanceAnalyzer.Domain.Model.Step do
  use Constructor

  @moduledoc """
  TODO Model for a step
  """
  alias DistributedPerformanceAnalyzer.Domain.Model.ExecutionModel

  constructor do
    field(:execution_model, ExecutionModel.t(), constructor: &ExecutionModel.new/1, enforce: true)
    field(:name, String.t(), constructor: &is_string/1)
    field(:step_number, :integer, constructor: &is_integer/1, enforce: true)
    field(:concurrency, :integer, constructor: &is_integer/1)
  end

  @impl Constructor
  def before_construct(input = %{execution_model: execution_model, step_number: step_number})
      when is_map(input) and step_number > 0 do
    %ExecutionModel{increment: increment, constant_load: constant_load} = execution_model

    input = Map.put(input, :name, "Step-#{step_number}")

    case constant_load do
      true -> {:ok, Map.put(input, :concurrency, increment)}
      false -> {:ok, Map.put(input, :concurrency, step_number * increment)}
    end
  end
end
