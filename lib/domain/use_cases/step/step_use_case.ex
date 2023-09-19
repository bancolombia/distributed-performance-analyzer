defmodule DistributedPerformanceAnalyzer.Domain.UseCase.Step.StepUseCase do
  @moduledoc """
  Step use case
  """

  alias DistributedPerformanceAnalyzer.Domain.Model.Config.Step

  def get_concurrency(%Step{number: number, scenario: scenario}) do
    scenario.strategy.increment * number
  end

  def get_name(%Step{number: number, scenario: scenario}) do
    "#{scenario.name} - step: #{number}"
  end
end
