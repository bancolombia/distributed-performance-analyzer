defmodule DistributedPerformanceAnalyzer.Application do
  alias DistributedPerformanceAnalyzer.Config.{AppConfig, AppRegistry, ConfigHolder}
  alias DistributedPerformanceAnalyzer.Utils.{CertificatesAdmin, CustomTelemetry, ConfigParser}
  alias DistributedPerformanceAnalyzer.Domain.Model.{Request, ExecutionModel}

  alias DistributedPerformanceAnalyzer.Domain.UseCase.{
    ConnectionPoolUseCase,
    ExecutionUseCase,
    MetricsCollectorUseCase,
    MetricsAnalyzerUseCase
  }

  use Application
  require Logger

  @default_runtime_config "config/performance.exs"

  def start(_type, [env]) do
    # config = AppConfig.load_config()

    CertificatesAdmin.setup()

    # children = all_env_children() ++ env_children(Mix.env())

    # CustomTelemetry.custom_telemetry_events()
    # opts = [strategy: :one_for_one, name: DistributedPerformanceAnalyzer.Supervisor]
    # Supervisor.start_link(children, opts)

    init(env)
  end

  def stop({:error, message}) do
    Logger.error(message)
    stop(:none)
  end

  def stop(env) when is_atom(env) do
    IO.puts("Finishing...")
    Application.stop(:distributed_performance_analyzer)

    if env != :test do
      System.stop(0)
    end
  end

  def all_env_children() do
    [
      {ConfigHolder, AppConfig.load_config()},
      {TelemetryMetricsPrometheus, [metrics: CustomTelemetry.metrics()]}
    ]
  end

  def env_children(:test) do
    []
  end

  def env_children(_other_env) do
    [
      {Finch, name: HttpFinch, pools: %{:default => [size: 500]}}
    ]
  end

  defp init(env) do
    if env != :test do
      with {:ok, _} <- File.stat(@default_runtime_config) do
        Config.Reader.read!(@default_runtime_config)
        |> Application.put_all_env()
      end

      Logger.configure(level: Application.fetch_env!(:logger, :level))
    end

    IO.puts(
      "JMeter Report enabled: #{Application.get_env(:distributed_performance_analyzer, :jmeter_report, true)}"
    )

    url = Application.fetch_env!(:distributed_performance_analyzer, :url)
    distributed = Application.fetch_env!(:distributed_performance_analyzer, :distributed)

    %{
      host: host,
      path: path,
      scheme: scheme,
      port: port,
      query: query
    } = ConfigParser.parse(url)

    connection_conf = {scheme, host, port}

    {:ok, request} =
      Application.fetch_env!(:distributed_performance_analyzer, :request)
      |> Map.put(:path, ConfigParser.path(path, query))
      |> Map.put(:url, url)
      |> Request.new()

    {:ok, execution_conf} =
      Application.fetch_env!(:distributed_performance_analyzer, :execution)
      |> Map.put(:request, request)
      |> ExecutionModel.new()

    children = [
      {ConfigHolder, execution_conf},
      {ConnectionPoolUseCase, connection_conf},
      {DynamicSupervisor,
       name: DPA.ConnectionSupervisor,
       strategy: :one_for_one,
       max_restarts: 10_000,
       max_seconds: 1},
      AppRegistry
    ]

    master_children = [
      {MetricsAnalyzerUseCase, execution_conf},
      MetricsCollectorUseCase,
      ExecutionUseCase
    ]

    children =
      if distributed == :none || distributed == :master do
        children ++ master_children
      else
        children
      end

    pid = Supervisor.start_link(children, strategy: :one_for_one)

    if execution_conf.steps > 0 && distributed == :none do
      ExecutionUseCase.launch_execution()
    end

    Process.monitor(Process.whereis(MetricsAnalyzerUseCase))

    receive do
      {:DOWN, _ref, :process, _pid, :normal} ->
        stop(env)
    end

    pid
  end
end
