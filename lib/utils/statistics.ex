defmodule DistributedPerformanceAnalyzer.Utils.Statistics do
  @moduledoc """
  Provides functions for statistics and mathematicals operations
  """
  def calculate_p90(partial) do
    Enum.count(partial.times)

    case Enum.count(partial.times) do
      0 ->
        partial

      _ ->
        sorted_times = Enum.sort(partial.times)
        n = length(sorted_times)
        index = 0.90 * n

        p90_calc =
          case is_round?(index) do
            true ->
              x = Enum.at(sorted_times, trunc(index))
              xp = Enum.at(sorted_times, trunc(index) + 1)

              ((x + xp) / 2)
              |> IO.inspect()
              |> round

            false ->
              index = round(index)
              Enum.at(sorted_times, index)
          end
          |> round()

        %{partial | p90: p90_calc, times: []}
    end
  end

  def is_round?(n) do
    case is_float(n) do
      true -> Float.floor(n) == n
      _ -> false
    end
  end

  def mean_latency(success_mean_latency, success_count) do
    success_mean_latency / (success_count + 0.00001)
  end

  def duration_segs(duration) do
    duration / 1000
  end

  def throughput(success_count, duration_segs) do
    success_count / duration_segs
  end

  def total_duration(steps_count, duration_segs) do
    steps_count * duration_segs
  end
end
