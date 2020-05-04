
defmodule Perf.LoadGenerator do
  use Task
  alias Perf.Model.Request

  def start(%LoadProcessModel{request: request, step_name: step_name, end_time: end_time}, concurrency) do
    Task.start(fn  ->
      conn = Perf.ConnectionPool.get_connection()
      try do
        results = generate_load(request, [], end_time, conn)
        Perf.MetricsCollector.send_metrics(results, step_name, concurrency)
      after
        Perf.ConnectionPool.return_connection(conn)
      end
    end)
  end

  defp generate_load(conf, results, end_time, conn) do
    result = request(conf, conn)
    if actual_time() < end_time do
      results = [result | results]
      generate_load(conf, results, end_time, conn)
    else
      results
    end
  end

  defp request(%Request{method: method, path: path, headers: headers, body: body}, conn) do
    {total_time, result} = try do
      Perf.ConnectionProcess.request(conn, method, path, headers, body)
    catch
      _, error -> {0, :invocation_error}
    end
  end

  defp actual_time do
    :erlang.system_time(:milli_seconds)
  end

end