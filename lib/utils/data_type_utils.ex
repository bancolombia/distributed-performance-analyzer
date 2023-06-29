defmodule DistributedPerformanceAnalyzer.Utils.DataTypeUtils do
  require Logger

  @moduledoc """
  Provides functions for normalize data
  """

  def normalize(%{__struct__: _} = value), do: value

  def normalize(%{} = map) do
    Map.to_list(map)
    |> Enum.map(fn {key, value} -> {String.to_atom(key), normalize(value)} end)
    |> Enum.into(%{})
  end

  def normalize(value) when is_list(value), do: Enum.map(value, &normalize/1)
  def normalize(value), do: value

  def base64_decode(string) do
    {:ok, value} = Base.decode64(string, padding: false)
    value
  end

  def extract_header(headers, name) when is_list(headers) do
    case extract_header!(headers, name) do
      {:ok, value} -> value
      default -> default
    end
  end

  def extract_header(headers, name) do
    {:error, "headers is not a list when finding #{inspect(name)}: #{inspect(headers)}"}
  end

  def extract_header!(headers, name) when is_list(headers) do
    out = Enum.filter(headers, create_evaluator(name))

    case out do
      [{_, value} | _] -> {:ok, value}
      _ -> {:ok, nil}
    end
  end

  defp create_evaluator(name) do
    fn
      {^name, _} -> true
      _ -> false
    end
  end

  def format("true", "boolean"), do: true
  def format("false", "boolean"), do: false

  def format(value, "number") when is_binary(value) do
    {number, ""} = Float.parse(value)
    number
  rescue
    _err ->
      Logger.warning("Error parsing #{value} to float")
      nil
  end

  def format(value, _type), do: value

  def system_time_to_milliseconds(system_time) do
    (system_time / 1.0e6) |> round()
  end

  def monotonic_time_to_milliseconds(monotonic_time) do
    monotonic_time |> System.convert_time_unit(:native, :millisecond)
  end

  def create_confirm_number do
    {:ok, Enum.random(10_000..99_999) |> to_string()}
  end

  def start_time(), do: System.monotonic_time()

  def duration_time(start),
    do: (System.monotonic_time() - start) |> monotonic_time_to_milliseconds()

  def format_failure(body) do
    String.replace(body, ",", ".")
  end
end
