defmodule DistributedPerformanceAnalyzer.Config.AppConfig do
  @moduledoc """
   Provides struct for app-config
  """

  @app_name :distributed_performance_analyzer

  def get_app_name(), do: @app_name
  def load(), do: Application.get_all_env(@app_name)
  def load!(property_name), do: Application.fetch_env!(@app_name, property_name)
  def load!(app_name, property_name), do: Application.fetch_env!(app_name, property_name)
  def set(config), do: Application.put_all_env(config)
end
