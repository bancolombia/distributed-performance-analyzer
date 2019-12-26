defmodule Perf.DepsContainer do
  @moduledoc false
  use GenServer

  @impl true
  def init(_) do
    :ets.new(__MODULE__, [:named_table, read_concurrency: true])
    {:ok, nil}
  end

  def lookup(name) do
    case :ets.lookup(__MODULE__, name) do
      [{^name, term}] -> {:ok, term}
      [] -> :error
    end
  end


end
