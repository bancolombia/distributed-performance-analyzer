defmodule DistributedPerformanceAnalyzer.Utils.EtsServer do
  use GenServer

  alias :ets, as: Ets
  alias :dets, as: Dets
  alias :mnesia, as: Mnesia

  @ets :dataset_ets
  @ets_r_concurrency :dataset_ets_r_concurrency
  @ets_w_concurrency :dataset_ets_w_concurrency
  @ets_concurrency :dataset_ets_concurrency
  @dets :dataset_dets
  @mnesia :dataset_mnesia
  @disk_mnesia :dataset_disk_mnesia

  def start() do
    GenServer.start(__MODULE__, nil, name: __MODULE__)
  end

  @impl true
  def init(nil) do
    clean()

    #    ets
    Ets.new(@ets, [:named_table, :public]) |> IO.inspect()

    Ets.new(@ets_r_concurrency, [
      :named_table,
      :public,
      {:write_concurrency, false},
      {:read_concurrency, true}
    ])
    |> IO.inspect()

    Ets.new(@ets_w_concurrency, [
      :named_table,
      :public,
      {:write_concurrency, true},
      {:read_concurrency, false}
    ])
    |> IO.inspect()

    Ets.new(@ets_concurrency, [
      :named_table,
      :public,
      {:write_concurrency, true},
      {:read_concurrency, true}
    ])
    |> IO.inspect()

    #    dets
    {:ok, _} = Dets.open_file(@dets, type: :set) |> IO.inspect()

    #    mnesia
    Mnesia.create_schema([node()])
    Mnesia.start()

    Mnesia.create_table(@mnesia, attributes: [:key, :value]) |> IO.inspect()

    Mnesia.create_table(@disk_mnesia, [
      {:attributes, [:key, :value]},
      {:disc_only_copies, [node()]},
      {:ram_copies, []}
    ])
    |> IO.inspect()

    {:ok, nil}
  end

  defp clean() do
    File.rm_rf("Mnesia.#{node()}")
    File.rm_rf(Atom.to_string(@dets))
    Mnesia.stop()
    Mnesia.delete_schema([node()])
  end

  @impl true
  def handle_call({:ets_write_item, index, value}, _, state),
    do: {:reply, Ets.insert(@ets, {index, value}), state}

  @impl true
  def handle_call({:dets_write_item, index, value}, _, state),
    do: {:reply, Dets.insert(@dets, {index, value}), state}

  def read_random_item(dataset_type, minValue, maxValue) do
    index = Enum.random(minValue..maxValue)

    case dataset_type do
      :ets -> Ets.lookup(@ets, index)
      :ets_r_concurrency -> Ets.lookup(@ets_r_concurrency, index)
      :ets_w_concurrency -> Ets.lookup(@ets_w_concurrency, index)
      :ets_concurrency -> Ets.lookup(@ets_concurrency, index)
      :dets -> Dets.lookup(@dets, index)
      :mnesia -> Mnesia.transaction(fn -> Mnesia.read({@mnesia, index}) end)
      :mnesia_dirty -> Mnesia.dirty_read({@mnesia, index})
      :mnesia_disk -> Mnesia.transaction(fn -> Mnesia.read({@disk_mnesia, index}) end)
      :mnesia_disk_dirty -> Mnesia.dirty_read({@disk_mnesia, index})
    end
  end

  def write_random_item(dataset_type, minValue, maxValue) do
    index = Enum.random(minValue..maxValue)

    message =
      "#{Atom.to_string(dataset_type)} timeStamp,elapsed,label,responseCode,responseMessage,threadName,dataType,success,failureMessage,bytes,sentBytes,grpThreads,allThreads,URL,Latency,IdleTime,Connect"

    case dataset_type do
      :ets ->
        Ets.insert(@ets, {index, message})

      :ets_r_concurrency ->
        Ets.insert(@ets_r_concurrency, {index, message})

      :ets_w_concurrency ->
        Ets.insert(@ets_w_concurrency, {index, message})

      :ets_concurrency ->
        Ets.insert(@ets_concurrency, {index, message})

      :dets ->
        Dets.insert(@dets, {index, message})

      :mnesia ->
        Mnesia.transaction(fn -> Mnesia.write({@mnesia, index, message}) end)

      :mnesia_dirty ->
        Mnesia.dirty_write({@mnesia, index, message})

      :mnesia_disk ->
        Mnesia.transaction(fn -> Mnesia.write({@disk_mnesia, index, message}) end)

      :mnesia_disk_dirty ->
        Mnesia.dirty_write({@disk_mnesia, index, message})
    end
  end
end
