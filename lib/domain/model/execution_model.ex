defmodule DistributedPerformanceAnalyzer.Domain.Model.ExecutionModel do
  use Constructor

  @moduledoc """
  TODO Execution model
  """

  constructor do
    field(:requests, :lists, constructor: &is_list/1)
    field(:steps, :integer, constructor: &is_integer/1)
    field(:increment, :integer, constructor: &is_integer/1)
    field(:duration, :integer, constructor: &is_integer/1)
    field(:dataset, :atomics | :string | :lists)
    field(:separator, :string, constructor: &is_string/1, default: ",")
    field(:constant_load, :boolean, constructor: &is_boolean/1, default: false)
    field(:mode, :atomics, constructor: &is_atom/1, default: :normal)
  end

  @impl Constructor
  def after_construct(%{dataset: dataset} = input) do
    case dataset do
      :none -> {:ok, input}
      value when is_binary(value) -> {:ok, input}
      value when is_list(value) -> {:ok, input}
      _ -> {:error, {:constructor, %{dataset: "Invalid dataset format!"}}}
    end
  end
end
