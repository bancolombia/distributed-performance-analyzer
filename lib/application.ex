defmodule DistributedPerformanceAnalyzer.Application do
  alias DistributedPerformanceAnalyzer.Config.{AppConfig, AppRegistry}
  alias DistributedPerformanceAnalyzer.Utils.CertificatesAdmin

  alias DistributedPerformanceAnalyzer.Domain.UseCase.{
    ConnectionPoolUseCase,
    Execution.ExecutionUseCase,
    MetricsCollectorUseCase,
    MetricsAnalyzerUseCase,
    Config.ConfigUseCase,
    Dataset.DatasetUseCase
  }

  use Application
  require Logger

  @default_runtime_config "config/performance.exs"

  def start(_type, [env]) do
    load_config(env)
    CertificatesAdmin.setup()

    distributed = AppConfig.load!(:distributed)
    children = all_env_children() ++ env_children(Mix.env(), distributed)

    # CustomTelemetry.custom_telemetry_events()
    opts = [strategy: :one_for_one, name: DistributedPerformanceAnalyzer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def all_env_children() do
    [
      #      {TelemetryMetricsPrometheus, [metrics: CustomTelemetry.metrics()]},
      {ConfigUseCase, AppConfig.load()}
    ]
  end

  def env_children(:test, _distributed), do: []

  def env_children(_other_env, distributed) do
    children = [
      {ConfigUseCase, Application.get_all_env(:distributed_performance_analyzer)},
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

    if distributed == :none || distributed == :master do
      children ++ master_children
    else
      children
    end
  end

  defp load_config(env) do
    if env != :test do
      with {:ok, _} <- File.stat(@default_runtime_config) do
        Config.Reader.read!(@default_runtime_config)
        |> AppConfig.set()
      end

      Logger.configure(level: AppConfig.load!(:logger, :level))
    end
  end

  def stop({:error, message}) do
    Logger.error(message)
    stop()
  end

  def stop() do
    IO.puts("Finishing...")
    Application.stop(AppConfig.get_app_name())
  end
end
