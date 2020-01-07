defmodule Perf.Application do
  @moduledoc false
  use Application

  alias Perf.LoadGenerator.Conf, as: Request
  alias Perf.Execution

  def start(_type, _args) do
    init()
  end


  def init() do
    connection_conf = Application.fetch_env!(:perf_analizer, :host)
    distributed = Application.fetch_env!(:perf_analizer, :distributed)
    request = struct(Request, Application.fetch_env!(:perf_analizer, :request))
    execution_conf = struct(Execution, Application.fetch_env!(:perf_analizer, :execution))
    execution_conf = put_in(execution_conf.request, request)
    execution_conf = put_in(execution_conf.collector, Perf.MetricsCollector)
    execution_deps = %{analyzer: Perf.MetricsAnalyzer, pool: Perf.ConnectionPool, load_step: Perf.LoadStep}

    children = [
      {Perf.ExecutionConf, execution_conf},
      {Perf.ConnectionPool, connection_conf},
    ]

    master_children = [
      {Perf.MetricsAnalyzer, execution_conf},
      Perf.MetricsCollector,
      {Execution, execution_deps}
    ]

    children = if distributed == :none || distributed == :master do
      children ++ master_children
      else
        children
      end

    pid = Supervisor.start_link(children, strategy: :one_for_all)
    if execution_conf.steps > 0 && distributed == :none do
      Perf.Execution.launch_execution()
    end
    pid
  end

end
