defmodule DistributedPerformanceAnalyzer.Domain.Model.Scenario do
  use Constructor
  alias DistributedPerformanceAnalyzer.Domain.Model.Config.{Request, Strategy}

  @moduledoc """
  Scenario model
  """

  constructor do
    field(:request, Request.t(), constructor: &Request.new/1)
    field(:dataset_name, :atomics | :string)
    field(:strategy, Strategy.t(), constructor: &Strategy.new/1)
    field(:depends, :atomics | :lists)
    #    TODO: Validate depends type
  end

  @impl Constructor
  def after_construct(%{dataset_name: dataset} = input) do
    case dataset do
      :none -> {:ok, input}
      value when is_binary(value) -> {:ok, input}
      _ -> {:error, {:constructor, %{dataset: "Invalid dataset format!"}}}
    end
  end
end
