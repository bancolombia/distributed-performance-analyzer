defmodule DistributedPerformanceAnalyzer.Domain.UseCase.Metrics.AnalyzerUseCase do
  @moduledoc """
  """
  alias :mnesia, as: Mnesia
  alias DistributedPerformanceAnalyzer.Utils.Statistics
  require Logger

  def init do
    Logger.debug("Starting metrics analyzer server...")
  end

  def step_results(id) do
    # TODO: get step duration to calculate throughput
    # TODO: fix concurrency
    # TODO: fix nil errors, invocation errors, protocol errors, conn errors
    concurrency = read_from_table(:request_success, :concurrency)
    throughput = throughput_calculation(0)
    min = response_time_calculations(:consolidated) |> elem(0)
    max = response_time_calculations(:consolidated) |> elem(1)
    avg = response_time_calculations(:consolidated) |> elem(2)
    p90 = response_time_calculations(:consolidated) |> elem(3)
    status_200 = count_table_records(:success_request)
    status_400 = count_table_records_by_response_code(:errors_request, 400)
    status_500 = count_table_records_by_response_code(:errors_request, 500)
    nil_conn_errors = 0
    invocation_errors = 0
    protocol_errors = 0
    conn_errors = 0
    errors = count_table_records(:errors_request)
    total = count_table_records(:consolidated)

    IO.puts(
      "Concurrency -> users: #{concurrency} - tps: #{throughput} | Latency -> min: #{min}ms - avg: #{avg}ms - max: #{max}ms - p90: #{p90}ms | Requests -> 2xx: #{status_200} - 4xx: #{status_400} - 5xx: #{status_500} | others_errors: #{nil_conn_errors + invocation_errors + protocol_errors + conn_errors} | total_errors: #{errors} - total_request: #{total}"
    )
  end

  # Functions for records calculations in mnesia tables

  def response_time_calculations(table_name) do
    Mnesia.transaction(fn ->
      records = Mnesia.all_keys(table_name)
      response_times = Enum.map(records, fn {:response_time, time} -> time end)
      response_times_list = Map.values(response_times)
      min_time = Statistics.min(response_times_list)
      max_time = Statistics.max(response_times_list)
      avg_time = Statistics.mean(response_times_list)
      p90 = Statistics.percentile(response_times_list, 90) || 0
      {min_time, max_time, avg_time, p90}
    end)
  end

  def throughput_calculation(step_duration) do
    # TODO get step duration
    total_success_request = count_table_records(:success_request)
    Statistics.throughput(total_success_request, step_duration)
  end

  def count_table_records(table_name) do
    Mnesia.transaction(fn ->
      table_data = Mnesia.all_keys(table_name)
      length(table_data)
    end)
  end

  def count_table_records_by_response_code(table_name, response_code) do
    Mnesia.transaction(fn ->
      pattern =
        {:errors_request, :_, response_code, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_,
         :_}

      records = Mnesia.match_object(pattern)
      count = length(records)
      count
    end)
  end

  ## Functions for mnesia tables
  def read_from_table(table_name, key) do
    Mnesia.transaction(fn ->
      Mnesia.read({table_name, key})
    end)
  end

  def delete_table(table_name) do
    Mnesia.delete_table(table_name)
  end
end
