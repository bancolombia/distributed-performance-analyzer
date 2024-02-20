defmodule DistributedPerformanceAnalyzer.Domain.UseCase.User.UserUseCase do
  @moduledoc """
  Use case for user that's responsible for sending and receiving request
  """

  use GenServer
  require Logger
  alias DistributedPerformanceAnalyzer.Config.AppConfig
  alias DistributedPerformanceAnalyzer.Domain.Model.{User, Config.Request}
  alias DistributedPerformanceAnalyzer.Domain.UseCase.Dataset.DatasetUseCase

  defstruct [:connection, :config]

  @http_client Application.compile_env!(AppConfig.get_app_name(), :http_client)

  def start_link(%User{} = config) do
    Logger.debug("Starting user for #{config.request.url}}...")
    GenServer.start_link(__MODULE__, config)
  end

  @impl true
  def init(config) do
    {:ok, %{connection: nil, config: config}, {:continue, :open_connection}}
  end

  @impl true
  def handle_continue(:open_connection, %{config: config} = state) do
    request = config.request

    case get_connection(request) do
      {:ok, connection} ->
        Logger.debug("Connection opened to #{request.url} in #{connection.time}ms")
        loop()
        {:noreply, %{state | connection: connection}}

      {:error, reason} ->
        Logger.error("Connection failed to #{request.url} due to #{inspect(reason)}")
        {:stop, reason, nil}
    end
  end

  @impl true
  def handle_info(:loop, %{config: config, connection: connection} = state) do
    request = replace_from_dataset(config.request, config.dataset_name)
    Logger.debug("Sending request #{inspect(request)}")

    {:ok, %{response: response, connection: connection}} = send_request(connection, request)
    Logger.debug(inspect(response))

    loop()
    #    TODO: send metrics
    {:noreply, %{state | connection: connection}}
  end

  defp loop(), do: Process.send_after(self(), :loop, 0)

  defp get_connection(%Request{} = request), do: @http_client.open_connection(request)
  defp close_connection(connection), do: @http_client.close_connection(connection)

  defp send_request(connection, %Request{} = request),
    do: @http_client.do_request(connection, request)

  defp replace_from_dataset(%Request{} = request, nil), do: request

  defp replace_from_dataset(%Request{} = request, dataset_name) when is_binary(dataset_name) do
    item = DatasetUseCase.get_random_item(dataset_name)
    replace_value = &(DatasetUseCase.replace_value(&1, item) || &1)

    %{request | body: replace_value.(request.body), headers: replace_value.(request.headers)}
  end

  @impl true
  def terminate(reason, state) do
    Logger.debug("Terminating user due to #{inspect(reason)}")
    if state && state.connection, do: close_connection(state.connection)
    :ok
  end

  #
  #  defp process_response(response) do
  #    #    TODO: process response
  #  end
end
