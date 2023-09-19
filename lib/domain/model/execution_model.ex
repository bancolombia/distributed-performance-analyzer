defmodule DistributedPerformanceAnalyzer.Domain.Model.ExecutionModel do
  use Constructor

  @moduledoc """
  TODO Execution model
  """

  alias DistributedPerformanceAnalyzer.Domain.Model.Request

  constructor do
    field(:request, Request.t(), constructor: &Request.new/1)
    field(:steps, :integer, constructor: &is_integer/1)
    field(:increment, :integer, constructor: &is_integer/1)
    field(:duration, :integer, constructor: &is_integer/1)
    field(:dataset, :atomics | String.t())
    field(:separator, String.t(), constructor: &is_string/1, default: ",")
    field(:constant_load, :boolean, constructor: &is_boolean/1, default: false)
  end

  @impl Constructor
  def after_construct(%{dataset: dataset} = input) do
    case dataset do
      :none -> {:ok, input}
      value when is_binary(value) -> {:ok, input}
      _ -> {:error, {:constructor, %{dataset: "Invalid dataset format!"}}}
    end
  end
end
