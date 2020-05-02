defmodule Perf.Application do
  @moduledoc false
  use Application

  alias Perf.Model.Request
  alias Perf.Execution

  def start(_type, _args) do
    init()
  end


  def init() do
    connection_conf = Application.fetch_env!(:perf_analizer, :host)
    distributed = Application.fetch_env!(:perf_analizer, :distributed)
    request = struct(Request, Application.fetch_env!(:perf_analizer, :request))
    execution_conf = struct(ExecutionModel, Application.fetch_env!(:perf_analizer, :execution))
    execution_conf = put_in(execution_conf.request, request)

    children = [
      {Perf.ExecutionConf, execution_conf},
      {Perf.ConnectionPool, connection_conf},
      {DynamicSupervisor, name: Perf.ConnectionSupervisor, strategy: :one_for_one, max_restarts: 10000, max_seconds: 1},
      Perf.AppRegistry
    ]

    master_children = [
      {Perf.MetricsAnalyzer, execution_conf},
      Perf.MetricsCollector,
      Execution
    ]

    children = if distributed == :none || distributed == :master do
      children ++ master_children
      else
        children
      end

    pid = Supervisor.start_link(children, strategy: :one_for_one)
    if execution_conf.steps > 0 && distributed == :none do
      Perf.Execution.launch_execution()
    end
    pid
  end

end
