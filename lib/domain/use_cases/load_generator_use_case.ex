defmodule DistributedPerformanceAnalyzer.Domain.UseCase.LoadGeneratorUseCase do
  use Task

  @moduledoc """
  TODO Updates usecase description
  """

  alias DistributedPerformanceAnalyzer.Domain.Model.{Request, LoadProcess}

  alias DistributedPerformanceAnalyzer.Domain.UseCase.{
    ConnectionPoolUseCase,
    MetricsCollectorUseCase,
    ConnectionProcessUseCase
  }

  ## TODO Add functions to business logic app
  def start(
        %LoadProcess{request: request, step_name: step_name, end_time: end_time},
        dataset,
        concurrency
      ) do
    Task.start(fn ->
      conn = ConnectionPoolUseCase.get_connection()

      try do
        results = generate_load(request, dataset, [], end_time, conn)
        MetricsCollectorUseCase.send_metrics(results, step_name, concurrency)
      after
        ConnectionPoolUseCase.return_connection(conn)
      end
    end)
  end

  defp generate_load(conf, dataset, results, end_time, conn) do
    item = get_random_item(dataset)
    result = request(conf, item, conn)

    if actual_time() < end_time do
      results = [result | results]
      generate_load(conf, dataset, results, end_time, conn)
    else
      results
    end
  end

  defp request(
         %Request{method: method, path: path, headers: headers, body: body, url: _url},
         item,
         conn
       ) do
    {_total_time, _result} =
      try do
        ConnectionProcessUseCase.request(conn, method, path, headers, replace_in_body(body, item))
      catch
        _, _error -> {0, :invocation_error}
      end
  end

  defp actual_time do
    :erlang.system_time(:milli_seconds)
  end

  defp get_random_item([]), do: nil

  defp get_random_item(list) when is_list(list) do
    # TODO: Improve random to static list
    Enum.at(list, Enum.random(0..(length(list) - 1)))
  end

  defp get_random_item(_opt), do: nil

  defp replace_in_body(body, item) when is_function(body), do: body.(item)

  defp replace_in_body(body, item) when is_map(item) do
    item = Map.put(item, "random", "#{Enum.random(1..10)}")

    Regex.replace(~r/{([a-z A-Z _-]+)?}/, body, fn _, match ->
      item[match]
    end)
  end

  defp replace_in_body(body, _item), do: body
end
