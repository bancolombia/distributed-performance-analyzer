defmodule Infrastructure.DrivenAdapters.RestConsumer.ApiRest.GenericRestClient do
  def method("GET"), do: :get
  def method("POST"), do: :post
  def method("PUT"), do: :put
  def method("DELETE"), do: :delete

  def make_request(url, headers) do
    {latency, _} = :timer.tc(fn -> {:ok, _} = get(url, headers) end)
    {latency, {:ok, latency}}
  end

  @spec make_request(any, any, any, any, any) :: {integer, {:ok, integer}}
  def make_request(url, method_str, headers, content_type, body) do
    {latency, _} =
      :timer.tc(fn -> {:ok, _} = request(url, method_str, headers, content_type, body) end)

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
    response =
      :httpc.request(
        method(method_str),
        {complete_url, format_headers(headers), to_charlist(content_type), to_charlist(body)},
        [],
        []
      )

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
