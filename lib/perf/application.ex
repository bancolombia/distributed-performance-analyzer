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
    request = struct(Request, Application.fetch_env!(:perf_analizer, :request))
    execution_conf = struct(Execution, Application.fetch_env!(:perf_analizer, :execution))
    execution_conf = put_in(execution_conf.request, request)
    execution_conf = put_in(execution_conf.collector, Perf.MetricsCollector)
    execution_deps = %{analyzer: Perf.MetricsAnalyzer, pool: Perf.ConnectionPool, load_step: Perf.LoadStep}

    children = [
      {Perf.ConnectionPool, connection_conf},
      {Perf.MetricsAnalyzer, execution_conf},
      Perf.MetricsCollector,
      {Execution, execution_deps}
    ]

    pid = Supervisor.start_link(children, strategy: :rest_for_one)
    if execution_conf.steps > 0 do
      Execution.launch_execution(execution_conf)
    end
    pid
  end

end
