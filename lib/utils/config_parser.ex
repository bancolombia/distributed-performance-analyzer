defmodule DistributedPerformanceAnalyzer.Utils.ConfigParser do
  @moduledoc """
  ConfigParser
  """

  def parse(url),
    do:
      :uri_string.parse(url)
      |> compose_url_parts()

  defp compose_url_parts(%{host: host, path: path, scheme: scheme} = parts) do
    %{
      host: host,
      path: path,
      scheme: String.to_atom(scheme),
      port: Map.get(parts, :port, default_port(scheme)),
      query: Map.get(parts, :query, "")
    }
  end

  defp compose_url_parts(parts) do
    raise "Malformed url: #{inspect(parts)}"
  end

  def path(path, nil), do: path
  def path(path, ""), do: path
  def path(path, query), do: "#{path}?#{query}"

  defp default_port("http"), do: 80
  defp default_port("https"), do: 443

  def parse_requests(data, url_base) do
    case data do
      [request | rest] when is_map(request) ->
        [parse_request(request, url_base) | parse_requests(rest, url_base)]

      request when is_map(request) ->
        [parse_request(request, url_base)]

      _ ->
        []
    end
  end

  defp parse_request(request, url_base) do
    url = if Map.has_key?(request, :url), do: request.url, else: url_base

    %{
      path: path,
      query: query
    } = parse(url)

    request
    |> Map.put(:path, path(path, query))
    |> Map.put(:url, url)
  end
end
