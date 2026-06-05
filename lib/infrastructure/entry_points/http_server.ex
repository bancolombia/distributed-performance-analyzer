defmodule DistributedPerformanceAnalyzer.Infrastructure.EntryPoints.HttpServer do
  @moduledoc """
  Starts a Cowboy HTTP server on the port configured by :http_port (default 8083).
  Only added to the supervision tree when :enable_server is true in app config.
  """

  require Logger

  alias DistributedPerformanceAnalyzer.Infrastructure.EntryPoints.DpaRouter

  def child_spec(_opts) do
    port = Application.get_env(:distributed_performance_analyzer, :http_port, 8083)
    Logger.info("Starting DPA HTTP server on port #{port}")
    Plug.Cowboy.child_spec(scheme: :http, plug: DpaRouter, options: [port: port])
  end
end
