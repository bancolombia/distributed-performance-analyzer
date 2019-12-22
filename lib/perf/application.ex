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

    children = [
      {Perf.ConnectionPool, connection_conf},
      Perf.MetricsCollector,
      {Execution, execution_conf},
      {Perf.MetricsAnalyzer, execution_conf}
    ]

    Supervisor.start_link(children, strategy: :rest_for_one)

  end

end
