defmodule Perf.Application do
  @moduledoc false
  use Application

  alias Perf.Model.Request
  alias Perf.Execution
  @default_runtime_config "config/performance.exs"

  def start(_type, _args) do
    init()
  end

  def init() do
    with {:ok, _} <- File.stat(@default_runtime_config) do
      Config.Reader.read!(@default_runtime_config)
      |> Application.put_all_env()
    end
    url = Application.fetch_env!(:perf_analyzer, :url)
    %{
      host: host,
      path: path,
      scheme: scheme,
      port: port,
      query: query,
    } = ConfParser.parse(url)

    IO.puts "JMeter Report enabled: #{Application.get_env(:perf_analyzer, :jmeter_report, true)}"

    connection_conf = {scheme, host, port}

    distributed = Application.fetch_env!(:perf_analyzer, :distributed)

    %{method: method, headers: headers, body: body} = struct(Request, Application.fetch_env!(:perf_analyzer, :request))
    request = struct(
      Request,
      %{method: method, path: ConfParser.path(path, query), headers: headers, body: body, url: url}
    )

    execution_conf = struct(ExecutionModel, Application.fetch_env!(:perf_analyzer, :execution))
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

defmodule ConfParser do
  def parse(url),
      do: :uri_string.parse(url)
          |> compose_url_parts()

  defp compose_url_parts(%{host: host, path: path, scheme: scheme} = parts) do
    %{
      host: host,
      path: path,
      scheme: String.to_atom(scheme),
      port: Map.get(parts, :port, default_port(scheme)),
      query: Map.get(parts, :query, ""),
    }
  end
  defp compose_url_parts(parts) do
    raise "Malformed url: #{inspect(parts)}"
  end

  def path(path, nil), do: path
  def path(path, ""), do: path
  def path(path, query), do: "#{path}?#{query}"

  defp default_port("http"), do: 80
  defp default_port("https"), do: 443
end
