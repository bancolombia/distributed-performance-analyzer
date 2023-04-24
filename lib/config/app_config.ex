defmodule DistributedPerformanceAnalyzer.Config.AppConfig do
  @moduledoc """
   Provides struct for app-config
  """

  defstruct [
    :api_rest_url,
    :enable_server,
    :http_port
  ]

  def load_config do
    %__MODULE__{
      api_rest_url: load(:api_rest_url),
      enable_server: load(:enable_server),
      http_port: load(:http_port)
    }
  end

  defp load(property_name),
    do: Application.fetch_env!(:distributed_performance_analyzer, property_name)
end
