defmodule Perf.LoadStep do
  @moduledoc false

  def start_step(conf) do
    #TODO: Agregar timeout y manejar errores remotos
    :rpc.multicall(__MODULE__, :start_step_local, [conf])
  end

  def start_step_local({conf = %Perf.LoadGenerator.Conf{}, step, duration, concurrency, collector}) do
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
