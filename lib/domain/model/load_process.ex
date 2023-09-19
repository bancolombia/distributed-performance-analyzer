defmodule DistributedPerformanceAnalyzer.Domain.Model.LoadProcess do
  use Constructor

  @moduledoc """
  TODO Steps orchestration
  """
  alias DistributedPerformanceAnalyzer.Domain.Model.Config.{Step, Request}
  alias DistributedPerformanceAnalyzer.Domain.UseCase.Step.StepUseCase

  constructor do
    field(:request, Request.t(), constructor: &Request.new/1, enforce: true)
    field(:step_name, String.t(), constructor: &is_string/1, enforce: true)
    field(:end_time, :integer, constructor: &is_integer/1, enforce: true)
  end

  @impl Constructor
  def before_construct(%Step{scenario: scenario} = step) do
    {:ok,
     %{
       request: scenario.request,
       step_name: StepUseCase.get_name(step),
       end_time: :erlang.system_time(:milli_seconds) + scenario.strategy.duration
     }}
  end
end
