defmodule DistributedPerformanceAnalyzer.Application do
  alias DistributedPerformanceAnalyzer.Config.{AppConfig, AppRegistry}
  alias DistributedPerformanceAnalyzer.Utils.{CertificatesAdmin, CustomTelemetry}

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
    Supervisor.start_link(children, opts) |> init(env, distributed)
  end

  def all_env_children() do
    [
      #      {TelemetryMetricsPrometheus, [metrics: CustomTelemetry.metrics()]},
      {ConfigUseCase, AppConfig.load()}
    ]
  end

  def env_children(:test, _distributed) do
    []
  end

  def env_children(_other_env, distributed) do
    children = [
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

  defp init(pid, :test, _distributed), do: pid

  defp init(pid, env, distributed) do
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

  def stop({:error, message}) do
    Logger.error(message)
    stop(:none)
  end

  def stop(env) when is_atom(env) do
    IO.puts("Finishing...")
    Application.stop(AppConfig.get_app_name())

    if env != :test do
      System.stop(0)
    end
  end
end
