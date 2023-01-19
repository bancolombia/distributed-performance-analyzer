defmodule Perf.LoadGenerator do
  use Task
  alias Perf.Model.Request

  def start(%LoadProcessModel{request: request, step_name: step_name, end_time: end_time}, dataset, concurrency) do
    Task.start(fn  ->
      conn = Perf.ConnectionPool.get_connection()

      try do
        results = generate_load(request, dataset, [], end_time, conn)
        Perf.MetricsCollector.send_metrics(results, step_name, concurrency)
      after
        Perf.ConnectionPool.return_connection(conn)
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

  defp request(%Request{method: method, path: path, headers: headers, body: body, url: _url}, item, conn) do
    {_total_time, _result} =
      try do
        Perf.ConnectionProcess.request(conn, method, path, headers, replace_in_body(body, item))
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
    Enum.at(list, Enum.random(0..length(list)))
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


defmodule GenericRestClient do


  def method("GET"), do: :get
  def method("POST"), do: :post
  def method("PUT"), do: :put
  def method("DELETE"), do: :delete

  def make_request(url, headers) do
    {latency, _} = :timer.tc(fn  -> {:ok, _} = get(url, headers) end)
    {latency, {:ok, latency}}
  end

  def make_request(url, method_str,  headers, content_type, body) do
    {latency, _} = :timer.tc(fn  -> {:ok, _} = request(url, method_str, headers, content_type, body) end)
    {latency, {:ok, latency}}
#    ref = make_ref
#    pid = self()
#    child = spawn(fn  ->
#    try do
#        {latency, _} = :timer.tc(fn  -> {:ok, _} = request(url, method_str, headers, content_type, body) end)
#        result = {latency, {:ok, latency}}
#        send(pid, {ref, result})
#        catch
#        _type, err -> send(pid, {ref, {0, :invocation_error}})
#    end
#    end)
#
#    receive do
#      {^ref, result} -> result
#      after
#       4000 ->
#         Process.exit(child, :kill)
#         {0, :invocation_error}
#    end

  end

  def request(url, method_str, headers, content_type, body) do
    complete_url = to_charlist(url)
#    response = :httpc.request(method(method_str), {complete_url, format_headers(headers), to_charlist(content_type), to_charlist(body)}, [{:timeout, 800} , {:connect_timeout, 800}], [])
    response = :httpc.request(method(method_str), {complete_url, format_headers(headers), to_charlist(content_type), to_charlist(body)}, [], [])
    case response do
      {:ok, {{_, 200, _}, _, body}} -> {:ok, to_string(body)}
      {:ok, {{_, 204, _}, _, body}} -> {:ok, to_string(body)}
#      {:ok, {{_, 409, _}, _, body}} -> {:ok, to_string(body)}
#      {:ok, {{_, 412, _}, _, body}} -> {:ok, to_string(body)}
      reason -> {:error, reason}
    end
  end

  def get(url, headers) do
    complete_url = to_charlist(url)
    response = :httpc.request(:get, {complete_url, format_headers(headers)}, [], [])
    case response do
      {:ok, {{_, 200, _}, _, body}} -> {:ok, to_string(body)}
      reason -> {:error, reason}
    end
  end


  defp format_headers(headers) do
    Enum.map(headers, fn {name, value} -> {to_charlist(name), to_charlist(value)} end)
  end

end
