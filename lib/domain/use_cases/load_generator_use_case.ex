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
        %LoadProcess{requests: requests, step_name: step_name, end_time: end_time, mode: mode},
        dataset,
        concurrency
      ) do
    Task.start(fn ->
      conn = ConnectionPoolUseCase.get_connection()

      try do
        results = generate_load(requests, dataset, [], end_time, conn, concurrency, mode)
        MetricsCollectorUseCase.send_metrics(results, step_name, concurrency)
      after
        ConnectionPoolUseCase.return_connection(conn)
      end
    end)
  end

  defp generate_load(requests, dataset, results, end_time, conn, concurrency, :sequential) do
    result =
      requests
      |> Enum.map(fn x ->
        item = DatasetUseCase.get_random_item(dataset)
        request(x, item, conn, concurrency)
      end)

    if actual_time() < end_time do
      results = result ++ results
      generate_load(requests, dataset, results, end_time, conn, concurrency, :sequential)
    else
      results
    end
  end

  defp generate_load(requests, dataset, results, end_time, conn, concurrency, :parallel) do
    result =
      requests
      |> Task.async_stream(
        fn request ->
          new_conn = ConnectionPoolUseCase.get_connection()
          item = DatasetUseCase.get_random_item(dataset)
          data = request(request, item, new_conn, concurrency)
          ConnectionPoolUseCase.return_connection(new_conn)
          data
        end,
        max_concurrency: length(requests)
      )
      |> Enum.map(fn {:ok, result} -> result end)
      |> Enum.to_list()

    if actual_time() < end_time do
      results = result ++ results
      generate_load(requests, dataset, results, end_time, conn, concurrency, :parallel)
    else
      results
    end
  end

  defp generate_load(requests, dataset, results, end_time, conn, concurrency, :normal) do
    item = DatasetUseCase.get_random_item(dataset)
    request = Enum.random(requests)
    result = request(request, item, conn, concurrency)

    if actual_time() < end_time do
      results = [result | results]
      generate_load(requests, dataset, results, end_time, conn, concurrency, :normal)
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
