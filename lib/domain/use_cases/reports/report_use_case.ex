defmodule DistributedPerformanceAnalyzer.Domain.UseCase.Reports.ReportUseCase do
  @moduledoc """
  Provides functions for generating reports, based on the results of the step
  """
  alias :mnesia, as: Mnesia

  #  TODO: init, create tables (step results)
  alias DistributedPerformanceAnalyzer.Domain.UseCase.CollectorUseCase

  def init do
    Mnesia.start()
    Mnesia.create_schema([node()])
  end

  def start_step_collector(id) do
    #    TODO: Create mnesia tables
    #    TODO: timeStamp with id user
    #    (if jmeter true, ordered set too)
    create_table(:errors_request, [
      :timeStamp,
      :response_code,
      :type_error,
      :response_time,
      :concurrency
    ])

    create_table(:success_request, [:timeStamp, :responseCode, :response_time, :concurrency])

    create_table(:consolidated, [
      :timeStamp,
      :elapsed,
      :label,
      :responseCode,
      :responseMessage,
      :threadName,
      :dataType,
      :success,
      :failureMessage,
      :bytes,
      :sentBytes,
      :grpThreads,
      :allThreads,
      :url,
      :latency,
      :idleTime,
      :connect
    ])
  end

  defp create_table(table_name, attributes) do
    # TODO: table ordered_set
    Mnesia.create_table(table_name, [
      {:type, :duplicate_bag},
      {:attributes, attributes}
    ])
  end
end
