defmodule DistributedPerformanceAnalyzer.Domain.Model.Scenario do
  use Constructor
  alias DistributedPerformanceAnalyzer.Domain.Model.{Scenario, Config.Request, Config.Strategy}

  @moduledoc """
  Scenario model
  """

  constructor do
    field(:name, String.t(), constructor: &is_string/1)
    field(:request, Request.t(), constructor: &Request.new/1)
    field(:strategy, Strategy.t(), constructor: &Strategy.new/1)

    field(:dataset_name, String.t(),
      constructor: &is_string_or_nil/1,
      default: nil,
      enforce: false
    )

    field(:depends, String.t() | :lists,
      constructor: &Scenario.dependencies_valid?/1,
      default: nil,
      enforce: false
    )
  end

  def dependencies_valid?(depends) do
    case depends do
      depends when is_binary(depends) or is_nil(depends) ->
        {:ok, depends}

      depends when is_list(depends) ->
        if Enum.all?(depends, &is_binary/1),
          do: {:ok, depends},
          else: {:error, "Invalid value #{inspect(depends)} for depends!"}

      _ ->
        {:error, "Invalid value #{inspect(depends)} for depends!"}
    end
  end
end
