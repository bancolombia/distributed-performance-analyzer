defmodule DistributedPerformanceAnalyzer.Domain.UseCase.User.UserUseCase do
  @moduledoc """
  Use case for user that's responsible for sending and receiving request
  """

  use GenServer
  require Logger
  alias DistributedPerformanceAnalyzer.Config.AppConfig
  alias DistributedPerformanceAnalyzer.Domain.Model.User

  @http_client Application.compile_env!(AppConfig.get_app_name(), :http_client)

  def start_link(%User{} = config) do
    Logger.debug("Starting user for #{config.request.url}}...")
    GenServer.start_link(__MODULE__, config)
  end

  def init(config) do
    {:ok, config}
  end

  #  def start() do
  #    #    TODO: start to send requests
  #  end
  #
  #  defp get_connection(endpoint) do
  #    #    TODO: get connection
  #  end
  #
  #  defp send_request(connection, params) do
  #    #    TODO: send request
  #  end
  #
  #  defp process_response(response) do
  #    #    TODO: process response
  #  end
end
