defmodule DistributedPerformanceAnalyzer.Domain.UseCase.LoadGeneratorUseCase do
  use Task

  @moduledoc """
  TODO Updates usecase description
  """

  alias DistributedPerformanceAnalyzer.Domain.Model.{Request, LoadProcess}

  alias DistributedPerformanceAnalyzer.Domain.UseCase.{
    ConnectionPoolUseCase,
    MetricsCollectorUseCase,
    ConnectionProcessUseCase,
    Dataset.DatasetUseCase
  }

  ## TODO Add functions to business logic app
  def start(
        %LoadProcess{request: request, step_name: step_name, end_time: end_time},
        _dataset,
        concurrency
      ) do
    Task.start(fn ->
      conn = ConnectionPoolUseCase.get_connection()

      try do
        results = generate_load(request, [], end_time, conn, concurrency)
        MetricsCollectorUseCase.send_metrics(results, step_name, concurrency)
      after
        ConnectionPoolUseCase.return_connection(conn)
      end
    end)
  end

  defp generate_load(conf, results, end_time, conn, concurrency) do
    item = DatasetUseCase.get_random_item()
    result = request(conf, item, conn, concurrency)

    if actual_time() < end_time do
      results = [result | results]
      generate_load(conf, results, end_time, conn, concurrency)
    else
      results
    end
  end

  defp request(
         %Request{method: method, path: path, headers: headers, body: body, url: _url},
         item,
         conn,
         concurrency
       ) do
    {_total_time, _result} =
      try do
        ConnectionProcessUseCase.request(
          conn,
          method,
          path,
          DatasetUseCase.replace_value(headers, item),
          DatasetUseCase.replace_value(body, item),
          concurrency
        )
      catch
        _, _error -> {0, :invocation_error}
      end
  end

  defp actual_time do
    :erlang.system_time(:milli_seconds)
  end
end
