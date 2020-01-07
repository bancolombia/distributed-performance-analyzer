defmodule Perf.LoadStep do
  @moduledoc false



  def start_step({conf, step, duration, concurrency, collector}, pool) do
    #TODO: Agregar timeout y manejar errores remotos
    node_list = [Node.self | Node.list]
    loads = distribute_load(node_list, concurrency)
    node_count = Enum.count(node_list)

    Enum.zip(node_list, loads)
      |> Enum.map(fn {node, load} ->
          IO.puts("Starting with #{inspect(node)} and #{inspect(load)}")
          :rpc.async_call(node, __MODULE__, :start_step_local, [{conf, step, duration, load, collector}, pool])
        end)
      |> Enum.map(&:rpc.yield/1)

  end

  def distribute_load(node_list, concurrency) do
    node_count = Enum.count(node_list)
    per_node = div(concurrency, node_count)
    node_list
        |> Enum.map(fn _ -> per_node end)
        |> add_rem([], rem(concurrency, node_count))
  end

  def add_rem(loads, added, to_add) do
    case loads do
      [x | xs] when to_add > 0 -> add_rem(xs, added ++ [x + 1], to_add - 1)
      [x | xs] -> add_rem(xs, added ++ [x], to_add)
      _ -> added
    end
  end

  def start_step_local({conf = %Perf.LoadGenerator.Conf{}, step, duration, concurrency, collector}, pool) do
    IO.inspect(pool.ensure_capacity(concurrency))
    launch_config = create_conf(conf, duration, step, collector)
    loads = 1..concurrency |>
      Enum.map(fn _ -> start_load(launch_config) end) |>
      Enum.map(fn ref -> wait_for(ref, duration + 1000) end)

    IO.puts("#{Enum.count(loads)} Processes started for step: #{step}")
  end

  defp start_load(launch_config) do
    {:ok, pid} = Perf.LoadGenerator.start_link(launch_config)
    Process.monitor(pid)
  end

  defp wait_for(ref, timeout) do
    receive do
      {:DOWN, ^ref, _, _, _} -> :load_end
    after
      timeout ->
        IO.puts("Process timeout #{inspect(ref)}")
        :load_timeout
    end
  end

  defp create_conf(conf, duration, step, collector) do
    end_time = :erlang.system_time(:milli_seconds) + duration
    {conf, step, end_time, collector}
  end

end
