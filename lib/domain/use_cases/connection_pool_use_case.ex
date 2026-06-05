defmodule DistributedPerformanceAnalyzer.Domain.UseCase.ConnectionPoolUseCase do
  @moduledoc """
  ConnectionPoolUseCase is module manages the connection pool
  """
  alias DistributedPerformanceAnalyzer.Domain.UseCase.ConnectionProcessUseCase
  alias DistributedPerformanceAnalyzer.Config.AppRegistry
  alias DistributedPerformanceAnalyzer.Utils.DpaEvent

  use GenServer
  require Logger

  def start_link({scheme, host, port}) do
    Logger.debug("Starting connection pool server...")
    GenServer.start_link(__MODULE__, {scheme, host, port}, name: __MODULE__)
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
  def init({scheme, host, port}) do
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

    if capacity > actual do
      to_create = capacity - actual
      actual_from = total_cap + 1
      capacity_to = total_cap + 1 + to_create

      results =
        Enum.map(actual_from..capacity_to, fn id -> create_connection(scheme, host, port, id) end)

      {successes, failures} = Enum.split_with(results, &match?({:ok, _}, &1))

      if failures != [] do
        Logger.warning(
          "Failed to create #{length(failures)} connections out of #{length(results)} requested"
        )

        DpaEvent.emit(%{
          type: "connection_pool_error",
          failed_count: length(failures),
          total_requested: length(results)
        })
      end

      names = Enum.map(successes, fn {:ok, name} -> name end)

      {:reply, {:ok, length(names)},
       {scheme, host, port, names ++ pool, total_cap + to_create + 1}}
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

    case DynamicSupervisor.start_child(
           DPA.ConnectionSupervisor,
           {ConnectionProcessUseCase, {scheme, host, port, name}}
         ) do
      {:ok, _pid} -> {:ok, name}
      {:error, reason} -> {:error, reason}
    end
  end
end
