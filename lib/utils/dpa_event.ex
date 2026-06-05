defmodule DistributedPerformanceAnalyzer.Utils.DpaEvent do
  @moduledoc """
  Centralized DPA event emitter.

  Every call to `emit/1` does three things in order:
  1. Writes "DPA_EVENT <json>" to stdout (preserves existing behavior).
  2. Appends the JSON line to `config/dpa_events.log` (NDJSON, readable from host via bind-mount).
  3. Pushes the event into the in-memory LogBuffer for HTTP polling on :8083.

  Call `rotate_log/0` at the start of each fresh execution (not resumes) to
  truncate the file so each run has its own clean log.
  """

  require Logger

  alias DistributedPerformanceAnalyzer.Infrastructure.EntryPoints.LogBuffer

  @log_path "config/dpa_events.log"

  @spec emit(map()) :: :ok
  def emit(payload) when is_map(payload) do
    timestamped = Map.put(payload, :timestamp, iso8601_now())
    json = Jason.encode!(timestamped)
    IO.puts("DPA_EVENT " <> json)
    append_to_file(json)
    push_to_buffer(timestamped)
    :ok
  end

  @spec rotate_log() :: :ok
  def rotate_log do
    case File.write(@log_path, "") do
      :ok ->
        :ok

      {:error, reason} ->
        Logger.warning("DpaEvent: could not rotate log file: #{inspect(reason)}")
    end
  end

  defp append_to_file(json) do
    case File.write(@log_path, json <> "\n", [:append]) do
      :ok ->
        :ok

      {:error, reason} ->
        Logger.warning("DpaEvent: failed to write log file: #{inspect(reason)}")
    end
  end

  defp push_to_buffer(event) do
    case Process.whereis(LogBuffer) do
      nil -> :ok
      _pid -> LogBuffer.push(event)
    end
  end

  defp iso8601_now do
    DateTime.utc_now() |> DateTime.to_iso8601()
  end
end
