defmodule Perf.ConnectionPool do
  use GenServer

  def start(scheme, host, port) do
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

  def capacity() do
    GenServer.call(__MODULE__, :capacity)
  end

  @impl true
  def init({scheme, host, port}) do
    {:ok, {scheme, host, port, []}}
  end

  @impl true
  def handle_call({:ensure_capacity, capacity}, from, {scheme, host, port, pool}) do
    to_create = capacity - Enum.count(pool)
    if to_create > 0 do
      created = Enum.map(1..to_create, fn _ -> create_connection(scheme, host, port) end)
      {:reply, {:ok, to_create}, {scheme, host, port, created ++ pool}}
    else
      {:reply, {:ok, 0}, {scheme, host, port, pool}}
    end
  end

  @impl true
  def handle_call(:capacity, from, {scheme, host, port, pool}) do
    {:reply, {:ok, Enum.count(pool)}, {scheme, host, port, pool}}
  end

  @impl true
  def handle_call(:get_connection, from, {scheme, host, port, pool}) do
    [head | tail] = pool
    {:reply, head, {scheme, host, port, tail}}
  end

  @impl true
  def handle_call({:return_connection, :fail_connection}, from, {scheme, host, port, pool}) do
    connection = create_connection(scheme, host, port)
    {:reply, :ok, {scheme, host, port, [connection | pool]}}
  end

  @impl true
  def handle_call({:return_connection, connection}, from, {scheme, host, port, pool}) do
    {:reply, :ok, {scheme, host, port, [connection | pool]}}
  end

  defp create_connection(scheme, host, port) do
    {:ok, conn} = Perf.ConnectionProcess.start_link({scheme, host, port})
    conn
  end


end
