defmodule DistributedPerformanceAnalyzer.Application do
  alias DistributedPerformanceAnalyzer.Config.{AppConfig, AppRegistry}
  alias DistributedPerformanceAnalyzer.Utils.{CertificatesAdmin, CustomTelemetry}

  alias DistributedPerformanceAnalyzer.Domain.UseCase.{
    ConnectionPoolUseCase,
    ExecutionUseCase,
    MetricsCollectorUseCase,
    MetricsAnalyzerUseCase,
    Config.ConfigUseCase,
    Dataset.DatasetUseCase
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
    #    Application.stop(:distributed_performance_analyzer)
    #
    #    if env != :test do
    #      System.stop(0)
    #    end
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

    config_envs = Application.get_all_env(:distributed_performance_analyzer)
    distributed = Application.get_env(:distributed_performance_analyzer, :distributed)

    children = [
      {ConfigUseCase, config_envs},
      DatasetUseCase,
      ConnectionPoolUseCase,
      {DynamicSupervisor,
       name: DPA.ConnectionSupervisor,
       strategy: :one_for_one,
       max_restarts: 10_000,
       max_seconds: 1},
      AppRegistry
    ]

    master_children = [
      MetricsAnalyzerUseCase,
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

    if distributed == :none do
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
