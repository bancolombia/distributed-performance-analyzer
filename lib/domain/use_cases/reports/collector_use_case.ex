defmodule DistributedPerformanceAnalyzer.Domain.UseCase.Metrics.CollectorUseCase do
  @moduledoc """
  """
  alias :mnesia, as: Mnesia
  use Task

  def consolidate_step(id) do
    #    TODO: Get all results from mnesia, save results to step results table
  end

  # def save_response(id, %Response{} = response) do
  def save_response(id, response) do
    #    TODO: Sort response type (success or error) and save response to mnesia (if jmeter true, parse and save)
    save_consolidated_response(id, response)

    case response.status do
      status when status >= 200 and status < 400 ->
        save_success_response(id, response)

      _ ->
        save_error_response(id, response)
    end
  end

  # TODO: fix %Response{}
  # def save_success_response(id, %Response{} = response) do
  def save_success_response(id, response) do
    Mnesia.transaction(fn ->
      record = %{
        timeStamp: response.timeStamp,
        responseCode: response.responseCode,
        response_time: response.response_time,
        concurrency: response.concurrency
      }

      Mnesia.write(record)
    end)
  end

  # def save_error_response(id, %Response{} = response) do
  def save_error_response(_id, response) do
    Mnesia.transaction(fn ->
      record = %{
        timeStamp: response.timeStamp,
        response_code: response.response_code,
        type_error: response.type_error,
        response_time: response.response_time,
        concurrency: response.concurrency
      }

      Mnesia.write(record)
    end)
  end

  # def save_consolidated_response(id, %Response{} = response) do
  def save_consolidated_response(id, response) do
    Mnesia.transaction(fn ->
      record = %{
        timestamp: response.timestamp,
        elapsed: response.elapsed,
        label: response.label,
        responseCode: response.responseCode,
        responseMessage: response.responseMessage,
        threadName: response.threadName,
        dataType: response.dataType,
        success: response.success,
        failureMessage: response.failureMessage,
        bytes: response.bytes,
        sentBytes: response.sentBytes,
        grpThreads: response.grpThreads,
        allThreads: response.allThreads,
        url: response.url,
        latency: response.latency,
        idleTime: response.idleTime,
        connect: response.connect
      }

      Mnesia.write(record)
    end)
  end
end
