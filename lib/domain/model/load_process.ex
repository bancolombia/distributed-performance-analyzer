defmodule DistributedPerformanceAnalyzer.Domain.Model.LoadProcess do
  use Constructor

  @moduledoc """
  TODO Steps orchestration
  """
  alias DistributedPerformanceAnalyzer.Domain.Model.{Step}

  constructor do
    field(:requests, :lists, constructor: &is_list/1, enforce: true)
    field(:step_name, :string, constructor: &is_string/1, enforce: true)
    field(:end_time, :integer, constructor: &is_integer/1, enforce: true)
    field(:mode, :atomics, constructor: &is_atom/1, default: :normal, enforce: false)
  end

  @impl Constructor
  def before_construct(input = %Step{execution_model: execution_model, name: name})
      when is_map(input) do
    {:ok,
     %{
       requests: execution_model.requests,
       step_name: name,
       mode: execution_model.mode,
       end_time: :erlang.system_time(:milli_seconds) + execution_model.duration
     }}
  end
end
