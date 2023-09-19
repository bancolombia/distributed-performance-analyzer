defmodule DistributedPerformanceAnalyzer.Domain.Model.LoadProcess do
  use Constructor

  @moduledoc """
  TODO Steps orchestration
  """
  alias DistributedPerformanceAnalyzer.Domain.Model.{Request, Step}

  constructor do
    field(:request, Request.t(), constructor: &Request.new/1, enforce: true)
    field(:step_name, String.t(), constructor: &is_string/1, enforce: true)
    field(:end_time, :integer, constructor: &is_integer/1, enforce: true)
  end

  @impl Constructor
  def before_construct(input = %Step{execution_model: execution_model, name: name})
      when is_map(input) do
    {:ok,
     %{
       request: execution_model.request,
       step_name: name,
       end_time: :erlang.system_time(:milli_seconds) + execution_model.duration
     }}
  end
end
