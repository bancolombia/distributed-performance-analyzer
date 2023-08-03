defmodule DistributedPerformanceAnalyzer.Domain.UseCase.Dataset.DatasetUseCase do
  @moduledoc """
  Use case for handle dataset
  """
  @dataset_parser Application.compile_env(
                    :distributed_performance_analyzer,
                    :dataset_parser
                  )

  @valid_extensions ["csv"]

  def parse(path, separator) do
    with {:ok, _path} <- file_exists?(path),
         {:ok, _path} <- has_valid_extension?(path) do
      parse_file(path, separator)
    else
      err -> err
    end
  end

  defp parse_file(path, separator) do
    cond do
      String.ends_with?(path, Enum.at(@valid_extensions, 0)) ->
        @dataset_parser.parse_csv(path, separator)
    end
  end

  defp file_exists?(path) do
    case @dataset_parser.file_exists?(path) do
      true -> {:ok, path}
      _ -> {:error, "Dataset file #{path} not found"}
    end
  end

  defp has_valid_extension?(path) do
    case String.ends_with?(path, @valid_extensions) do
      true -> {:ok, path}
      _ -> {:error, "Dataset file #{path} does not have a valid extension"}
    end
  end

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
