defmodule DistributedPerformanceAnalyzer.Domain.UseCase.Reports.ReportUseCase do
  @moduledoc """
  Provides functions for generating reports, based on the results of the step
  """

  #  TODO: init, create tables (step results)

  def start_step_collector(id) do
    #    TODO: Create mnesia tables
    #    (if jmeter true, ordered set too)
  end

  def consolidate_step(id) do
    #    TODO: Get all results from mnesia, save results to step results table
  end

  def save_response(id, %Response{} = response) do
    #    TODO: Sort response type (success or error) and save response to mnesia (if jmeter true, parse and save)
  end
end
