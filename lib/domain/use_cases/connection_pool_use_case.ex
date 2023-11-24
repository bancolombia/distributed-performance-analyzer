defmodule DistributedPerformanceAnalyzer.Domain.UseCase.ConnectionPoolUseCase do
  @moduledoc """
  ConnectionPoolUseCase is module manages the connection pool
  """

  alias DistributedPerformanceAnalyzer.Domain.Model.Config.Request

  alias DistributedPerformanceAnalyzer.Domain.UseCase.{
    ConnectionProcessUseCase,
    Config.ConfigUseCase
  }

  alias DistributedPerformanceAnalyzer.Config.AppRegistry
  alias DistributedPerformanceAnalyzer.Utils.DataTypeUtils

  use GenServer
  require Logger

  def start_link(_) do
    Logger.debug("Starting connection pool server...")
    #    TODO: do parallel
    %{request: request} = ConfigUseCase.get(:scenarios) |> Enum.at(0)
    GenServer.start_link(__MODULE__, request, name: __MODULE__)
  end

  def ensure_capacity(capacity) do
    GenServer.call(__MODULE__, {:ensure_capacity, capacity})
  end

  def get_connection() do
    GenServer.call(__MODULE__, :get_connection)
  end

  def return_connection(connection) do
    GenServer.call(__MODULE__, {:return_connection, connection})
  end

  @impl true
  def init(%Request{url: url}) do
    %{
      host: host,
      scheme: scheme,
      port: port
    } = DataTypeUtils.parse_url(url)

    {:ok, {scheme, host, port, [], 0}}
  end

  @impl true
  def handle_info(msg, state) do
    IO.puts("Message In Pool: #{inspect(msg)}")
    {:noreply, state}
  end

  @impl true
  def handle_call({:ensure_capacity, capacity}, _from, {scheme, host, port, pool, total_cap}) do
    actual = Enum.count(pool)
    to_create = capacity - actual

    if capacity > actual do
      actual_from = total_cap + 1
      capacity_to = total_cap + 1 + to_create

      created =
        Enum.map(actual_from..capacity_to, fn id -> create_connection(scheme, host, port, id) end)

      {:reply, {:ok, to_create}, {scheme, host, port, created ++ pool, total_cap + to_create + 1}}
    else
      {:reply, {:ok, 0}, {scheme, host, port, pool, total_cap}}
    end
  end

  @impl true
  def handle_call(:get_connection, _from, {scheme, host, port, [head | tail], total_cap}) do
    {:reply, head, {scheme, host, port, tail, total_cap}}
  end

  @impl true
  def handle_call(:get_connection, _from, {scheme, host, port, [], total_cap}) do
    {:reply, nil, {scheme, host, port, [], total_cap}}
  end

  @impl true
  def handle_call({:return_connection, connection}, _from, {scheme, host, port, pool, total_cap}) do
    {:reply, :ok, {scheme, host, port, [connection | pool], total_cap}}
  end

  defp create_connection(scheme, host, port, id) do
    name = AppRegistry.via_tuple(id)

    {:ok, _pid} =
      DynamicSupervisor.start_child(
        DPA.ConnectionSupervisor,
        {ConnectionProcessUseCase, {scheme, host, port, name}}
      )

    name
  end
end
