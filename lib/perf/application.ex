defmodule Perf.Application do
  @moduledoc false
  use Application

  alias Perf.Model.Request
  alias Perf.Execution
  alias MyRouter
  def start(_type, _args) do
    service()
  end
  def start_link do
    Agent.start_link(fn -> nil end, name: __MODULE__)
  end
  def add_to(input) do
    Agent.get_and_update(__MODULE__, fn (x) -> {input, input} end)
  end
  def get() do
    Agent.get(__MODULE__, fn x ->  x end)
  end

  def init(param1,param2,param3,param4) do
    connection_conf = param1
    distributed = param4
    request = struct(Request, param2)
    execution_conf = struct(ExecutionModel, param3)
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

  def service() do
    children = [
      {Plug.Cowboy, scheme: :http, plug: MyRouter, options: [port: 4001]}
    ]
    opts = [strategy: :one_for_one, name: Perf.Application.Supervisor]
    Supervisor.start_link(children, opts)
  end


end
