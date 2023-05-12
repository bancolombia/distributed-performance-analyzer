defmodule DistributedPerformanceAnalyzer.Utils.ConfigParser do
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
end
