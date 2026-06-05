defmodule DistributedPerformanceAnalyzer.Infrastructure.EntryPoints.LogBuffer do
  @max_size 500

  @moduledoc """
  In-memory ring-buffer of the last #{@max_size} DPA events.
  Used by DpaRouter to serve HTTP polling requests from the extension.
  """

  use GenServer

  def start_link(_), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  @spec push(map()) :: :ok
  def push(event), do: GenServer.cast(__MODULE__, {:push, event})

  @spec get_since(integer()) :: [map()]
  def get_since(since_ms) when is_integer(since_ms),
    do: GenServer.call(__MODULE__, {:get_since, since_ms})

  @spec get_all() :: [map()]
  def get_all, do: GenServer.call(__MODULE__, :get_all)

  @impl true
  def init(_), do: {:ok, []}

  @impl true
  def handle_cast({:push, event}, buffer) do
    {:noreply, [event | buffer] |> Enum.take(@max_size)}
  end

  @impl true
  def handle_call({:get_since, since_ms}, _from, buffer) do
    events =
      buffer
      |> Enum.filter(fn event ->
        case DateTime.from_iso8601(Map.get(event, :timestamp, "")) do
          {:ok, dt, _} -> DateTime.to_unix(dt, :millisecond) >= since_ms
          _ -> false
        end
      end)
      |> Enum.reverse()

    {:reply, events, buffer}
  end

  @impl true
  def handle_call(:get_all, _from, buffer) do
    {:reply, Enum.reverse(buffer), buffer}
  end
end
