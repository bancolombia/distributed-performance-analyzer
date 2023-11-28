defmodule DistributedPerformanceAnalyzer.Domain.UseCase.Dataset.DatasetUseCase do
  @moduledoc """
  Use case for handle dataset
  """

  alias DistributedPerformanceAnalyzer.Config.AppConfig
  alias DistributedPerformanceAnalyzer.Domain.Model.Config.Dataset
  alias DistributedPerformanceAnalyzer.Domain.UseCase.Config.ConfigUseCase

  use GenServer
  require Logger

  @file_system Application.compile_env!(AppConfig.get_app_name(), :file_system)
  @dataset_parser Application.compile_env!(AppConfig.get_app_name(), :dataset_parser)

  @valid_extensions [".csv"]

  def start_link(_) do
    Logger.debug("Starting dataset server...")
    GenServer.start_link(__MODULE__, ConfigUseCase.get(:datasets), name: __MODULE__)
  end

  @impl true
  def init(datasets) when is_list(datasets) do
    datasets |> Enum.map(&persists_dataset(&1))
    {:ok, nil}
  end

  defp persists_dataset({table_name, %Dataset{path: path, separator: separator, ordered: _}})
       when is_atom(table_name) do
    #    TODO: use ordered config
    :ets.new(table_name, [:named_table])

    if is_binary(path) do
      with {:ok, dataset} <- parse_file(path, separator) do
        dataset
        |> Enum.with_index(1)
        |> Enum.each(fn {value, index} -> :ets.insert(table_name, {index, value}) end)

        :ets.insert(table_name, {:length, length(dataset)})

        {:ok, %{table_name: table_name, index: 0}}
      else
        {:error, message} ->
          Logger.error(message)
          {:stop, :dataset_error}
      end
    else
      :ets.insert(table_name, {:length, -1})
      {:ok, nil}
    end
  end

  defp parse_file(path, separator) when is_binary(path) do
    Logger.info("Reading dataset file: #{path}")

    with {:ok, _path} <- file_exists?(path),
         {:ok, _path} <- has_valid_extension?(path),
         {:ok, _path} <- is_utf8_encoded?(path) do
      @dataset_parser.parse_csv(path, separator)
    else
      {:error, reason} -> Logger.error("Error reading dataset file: #{inspect(reason)}")
    end
  end

  defp file_exists?(path) do
    case @file_system.file_exists?(path) do
      true -> {:ok, path}
      _ -> {:error, "Dataset file #{path} not found"}
    end
  end

  defp has_valid_extension?(path) do
    case @file_system.has_valid_extension?(path, @valid_extensions) do
      true -> {:ok, path}
      _ -> {:error, "Dataset file #{path} does not have a valid extension"}
    end
  end

  defp is_utf8_encoded?(path) do
    case @file_system.has_utf8_encoding?(path) do
      true -> {:ok, path}
      _ -> {:error, "Dataset file #{path} is not UTF-8 encoded"}
    end
  end

  #  TODO: Add sequential item request from dataset

  def get_random_item(table_name) when is_binary(table_name),
    do: get_random_item(String.to_atom(table_name))

  def get_random_item(table_name) when is_atom(table_name) do
    unless table_name == :none do
      [length: length] = :ets.lookup(table_name, :length)

      if length > 0 do
        random = Enum.random(1..length)
        [{^random, value}] = :ets.lookup(table_name, random)
        value
      else
        nil
      end
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
