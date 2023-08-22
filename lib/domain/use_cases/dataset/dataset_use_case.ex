defmodule DistributedPerformanceAnalyzer.Domain.UseCase.Dataset.DatasetUseCase do
  @moduledoc """
  Use case for handle dataset
  """

  alias DistributedPerformanceAnalyzer.Domain.Model.ExecutionModel

  use GenServer
  require Logger

  @dataset_parser Application.compile_env(
                    :distributed_performance_analyzer,
                    :dataset_parser
                  )
  @valid_extensions ["csv"]

  def start_link(execution_config) do
    Logger.debug("Starting dataset server...")
    GenServer.start_link(__MODULE__, execution_config, name: __MODULE__)
  end

  @impl true
  def init(%ExecutionModel{dataset: dataset_path, separator: separator}) do
    :ets.new(__MODULE__, [:named_table, read_concurrency: true])

    if is_binary(dataset_path) do
      with {:ok, dataset} <- parse_file(dataset_path, separator) do
        dataset
        |> Enum.with_index()
        |> Enum.each(fn {value, index} -> :ets.insert(__MODULE__, {index, value}) end)

        :ets.insert(__MODULE__, {:length, length(dataset)})

        {:ok, %{index: 0}}
      else
        err ->
          Logger.error(err)
          {:stop, :dataset_error}
      end
    else
      :ets.insert(__MODULE__, {:length, -1})
      {:ok, nil}
    end
  end

  defp parse_file(path, separator) when is_binary(path) do
    Logger.info("Reading dataset file: #{path}")

    with {:ok, _path} <- file_exists?(path),
         {:ok, _path} <- has_valid_extension?(path) do
      @dataset_parser.parse_csv(path, separator)
    else
      err -> err
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

  def get_random_item() do
    [length: length] = :ets.lookup(__MODULE__, :length)

    if length > 0 do
      random = Enum.random(0..(length - 1))
      [{random, value}] = :ets.lookup(__MODULE__, random)
      value
    else
      nil
    end
  end

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
