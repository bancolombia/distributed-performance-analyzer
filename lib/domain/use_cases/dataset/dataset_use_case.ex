defmodule DistributedPerformanceAnalyzer.Domain.UseCase.Dataset.DatasetUseCase do
  def get_random_item([]), do: nil

  def get_random_item(list) when is_list(list) do
    # TODO: Improve random to static list
    Enum.at(list, Enum.random(0..(length(list) - 1)))
  end

  def get_random_item(_opt), do: nil

  def replace_value(values, item) when is_list(values) do
    Enum.map(values, fn {key, value} -> {key, replace_value(value, item)} end)
  end

  def replace_value(value, item) when is_function(value), do: value.(item)

  def replace_value(value, item) when is_map(item) do
    item = Map.put(item, "random", "#{Enum.random(1..10)}")

    Regex.replace(~r/{([a-z A-Z _-]+)?}/, value, fn _, match ->
      item[match]
    end)
  end

  def replace_value(value, _item), do: value
end
