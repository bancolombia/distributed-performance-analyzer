defmodule Perf.ConnectionPool do
  use GenServer
  require Logger
  @connection Perf.ConnectionProcess

  def start(scheme, host, port) do
    GenServer.start_link(__MODULE__, {scheme, host, port})
  end

  def start_link({scheme, host, port}) do
    GenServer.start_link(__MODULE__, {scheme, host, port}, name: __MODULE__)
  end

  def ensure_capacity(capacity) do
    GenServer.call(__MODULE__, {:ensure_capacity, capacity})
  end

  def request(pid, method, path, headers, body) do
    @connection.request(pid, method, path, headers, body)
  end

  def get_connection() do
    GenServer.call(__MODULE__, :get_connection)
  end

  def return_connection(connection) do
    GenServer.call(__MODULE__, {:return_connection, connection})
  end

  @impl true
  def init({scheme, host, port}) do
    :ok = :pg2.create(__MODULE__)
    :ok = :pg2.join(__MODULE__, self())
    {:ok, {scheme, host, port, []}}
  end

  @impl true
  def handle_call({:ensure_capacity, capacity}, _from, {scheme, host, port, pool}) do
    actual = Enum.count(pool)
    to_create = capacity - actual

    if capacity > actual do
      actual = actual + 1
      created = Enum.map(actual..capacity, fn id -> create_connection(scheme, host, port, id) end)
      {:reply, {:ok, to_create}, {scheme, host, port, created ++ pool}}
    else
      {:reply, {:ok, 0}, {scheme, host, port, pool}}
    end
  end

  @impl true
  def handle_info(msg, state) do
    IO.puts("Message In Pool: #{inspect(msg)}")
    {:noreply, state}
  end

  @impl true
  def handle_call(:get_connection, _from, {scheme, host, port, [head | tail]}) do
    {:reply, head, {scheme, host, port, tail}}
  end

  @impl true
  def handle_call(:get_connection, _from, {scheme, host, port, []}) do
    {:reply, nil, {scheme, host, port, []}}
  end

  #@impl true
  #def handle_call({:return_connection, :fail_connection}, _from, {scheme, host, port, pool}) do
  #  connection = create_connection(scheme, host, port)
  #  {:reply, :ok, {scheme, host, port, [connection | pool]}}
  #end

  @impl true
  def handle_call({:return_connection, connection}, _from, {scheme, host, port, pool}) do
    {:reply, :ok, {scheme, host, port, [connection | pool]}}
  end

  defp create_connection(scheme, host, port, id) do
    name = Perf.AppRegistry.via_tuple(id)
    {:ok, pid} = DynamicSupervisor.start_child(Perf.ConnectionSupervisor, {@connection, {scheme, host, port, name}})
    name
  end


end
