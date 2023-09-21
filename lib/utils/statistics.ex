defmodule DistributedPerformanceAnalyzer.Utils.Statistics do
  @moduledoc """
  Provides functions for statistics and mathematical operations
  """

  @doc """
  Get the minimum value from a list

  ## Examples
      iex> alias DistributedPerformanceAnalyzer.Utils.Statistics
      iex> Statistics.min([])
      nil
      iex> Statistics.min([1, 2, 3])
      1
  """
  def min([]), do: nil
  def min(list) when is_list(list), do: Enum.min(list)

  @doc """
  Get the maximum value from a list

  ## Examples
      iex> alias DistributedPerformanceAnalyzer.Utils.Statistics
      iex> Statistics.max([])
      nil
      iex> Statistics.max([1, 2, 3])
      3
  """
  def max([]), do: nil
  def max(list) when is_list(list), do: Enum.max(list)

  @doc """
  Calculate the mean from a list of numbers

  ## Examples
      iex> alias DistributedPerformanceAnalyzer.Utils.Statistics
      iex> Statistics.mean([])
      nil
      iex> Statistics.mean([1,2,3])
      2.0

  """
  def mean(list) when is_list(list), do: do_mean(list, 0, 0)
  defp do_mean([], 0, 0), do: nil
  defp do_mean([], t, l), do: t / l
  defp do_mean([x | xs], t, l), do: do_mean(xs, t + x, l + 1)

  @doc """
  Get the nth percentile from a list

  ## Examples
      iex> alias DistributedPerformanceAnalyzer.Utils.Statistics
      iex> Statistics.percentile([], 50)
      nil
      iex> Statistics.percentile([1], 50)
      1
      iex> Statistics.percentile([1,2,3,4,5,6,7,8,9],0)
      1
      iex> Statistics.percentile([1,2,3,4,5,6,7,8,9],80)
      7.4
      iex> Statistics.percentile([1,2,3,4,5,6,7,8,9],100)
      9
  """
  def percentile([], _), do: nil
  def percentile([x], _), do: x
  def percentile(list, 0), do: Enum.min(list)
  def percentile(list, 100), do: Enum.max(list)

  def percentile(list, n) when is_list(list) and is_number(n) do
    sorted_list = Enum.sort(list)
    rank = n / 100.0 * (length(list) - 1)
    index = trunc(rank)
    lower = Enum.at(sorted_list, index)
    upper = Enum.at(sorted_list, index + 1)
    lower + (upper - lower) * (rank - index)
  end

  @doc """
  Calculate the mean of a value and a count

  ## Examples
      iex> alias DistributedPerformanceAnalyzer.Utils.Statistics
      iex> Statistics.mean(10, 5)
      1.9999960000080002
  """
  def mean(value, count), do: value / (count + 0.00001)

  @doc """
  Convert milliseconds to seconds

  ## Examples
      iex> alias DistributedPerformanceAnalyzer.Utils.Statistics
      iex> Statistics.millis_to_seconds(5000)
      5.0
  """
  def millis_to_seconds(millis), do: millis / 1000

  @doc """
  Calculate the throughput of a count and a duration

  ## Examples
      iex> alias DistributedPerformanceAnalyzer.Utils.Statistics
      iex> Statistics.throughput(100,10)
      10.0
  """
  def throughput(count, duration), do: count / duration

  @doc """
  Calculate the duration of a count and a duration

  ## Examples
      iex> alias DistributedPerformanceAnalyzer.Utils.Statistics
      iex> Statistics.duration(10,100)
      1000
  """
  def duration(count, duration), do: count * duration
end
