
defmodule Perf.LoadGenerator do
  use Task
  alias Perf.Model.Request

  def start_link({conf = %Request{}, step, end_time, collector}) do
    Task.start_link(fn  ->
      conn = Perf.ConnectionPool.get_connection()
      try do
        results = generate_load(conf, [], end_time, conn)
        collector.send_metrics(results, step)
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
      Perf.ConnectionPool.request(conn, method, path, headers, body)
    catch
      _, error ->
        IO.puts(inspect(error))
        {0, :error}
    end
  end

  defp actual_time do
    :erlang.system_time(:milli_seconds)
  end

end