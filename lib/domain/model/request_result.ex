defmodule DistributedPerformanceAnalyzer.Domain.Model.RequestResult do
  use Constructor

  @moduledoc """
  TODO Result of a single request
  """

  constructor do
    field(:start, :integer, constructor: &is_integer/1, default: 0)
    field(:time_stamp, :integer, constructor: &is_integer/1, default: 0)
    field(:label, String.t(), constructor: &is_string/1, enforce: true)
    field(:thread_name, String.t(), constructor: &is_string/1, default: "", enforce: true)
    field(:grp_threads, :integer, constructor: &is_integer/1, default: 0)
    field(:all_threads, :integer, constructor: &is_integer/1, default: 0)
    field(:url, String.t(), constructor: &is_string/1, default: "", enforce: true)
    field(:elapsed, :float, constructor: &is_float/1, default: 0.0)
    field(:response_code, :integer, constructor: &is_integer/1, default: 0)
    field(:response_message, String.t(), constructor: &is_string/1, default: "")
    field(:data_type, String.t(), constructor: &is_string/1, default: "")
    field(:success, :boolean, constructor: &is_boolean/1, default: false)
    field(:failure_message, String.t(), constructor: &is_string/1, default: "")
    field(:bytes, :integer, constructor: &is_integer/1, default: 0)
    field(:sent_bytes, :integer, constructor: &is_integer/1, default: 0, enforce: true)
    field(:latency, :float, constructor: &is_float/1, default: 0.0)
    field(:idle_time, :float, constructor: &is_float/1, default: 0.0)
    field(:connect, :integer, constructor: &is_integer/1, default: 0, enforce: true)
    field(:received_bytes, String.t(), constructor: &is_string/1, default: "")
    field(:content_type, String.t(), constructor: &is_string/1, default: "")
  end

  @impl Constructor
  def before_construct(
        input = %{
          label: label,
          thread_name: thread_name,
          url: url,
          sent_bytes: sent_bytes,
          connect: connect,
          concurrency: concurrency
        }
      )
      when is_map(input) do
    {:ok,
     %{
       start: :erlang.monotonic_time(:millisecond),
       time_stamp: System.os_time(:millisecond),
       label: label,
       thread_name: thread_name,
       grp_threads: concurrency,
       all_threads: concurrency,
       url: url,
       sent_bytes: sent_bytes,
       connect: connect
     }}
  end
end
