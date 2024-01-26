defmodule DistributedPerformanceAnalyzer.Infrastructure.Adapters.Http.HttpClient do
  require Logger

  @moduledoc """
  Provides functions for making HTTP requests
  """

  alias DistributedPerformanceAnalyzer.Utils.DataTypeUtils
  use Tesla

  @client Tesla.client([], Tesla.Adapter.Mint)
  @adapter Tesla.Adapter.Mint
  @http_methods %{
    get: &Httpclient.get_request/4,
    post: &Httpclient.post_request/4,
    put: &Httpclient.put_request/4,
    delete: &Httpclient.delete_request/4,
    patch: &Httpclient.patch_request/4,
    options: &Httpclient.options_request/4,
    head: &Httpclient.head_request/4,
    trace: &Httpclient.trace_request/4
  }

  def init(url, method, body \\ "", headers \\ "", conn_reuse) do
    Utils.CertificatesAdmin.setup()

    start = :erlang.monotonic_time(:millisecond)

    %{
      host: host,
      path: path,
      port: port,
      query: query,
      scheme: scheme
    } = DataTypeUtils.parse(url)

    body_json = Jason.encode!(body)
    params = [method, url, body_json, headers]

    case connect(%{host: host, path: path, port: port, query: query, scheme: scheme}) do
      {:ok, conn} ->
        conn_time = :erlang.monotonic_time(:millisecond) - start
        time = [start, conn_time]
        handle_http_method(method, params, time, conn)

      {:error, _} = error ->
        Logger.warning("Error creating connection with #{url}}")
        error
    end
  end

  defp connect(%{host: host, path: path, port: port, scheme: scheme}) do
    Mint.HTTP.connect(scheme, host, port, options_mint(scheme))
  end

  defp handle_http_method(method, params, time, conn) do
    case Map.fetch(@http_methods, method) do
      {:ok, func} -> apply(func, [@client, params, time, conn])
      :error -> {:error, "Unsupported HTTP method"}
    end
  end

  ### definition of http methods

  def get_request(client, params, time, conn) do
    [method, url, body, headers] = params

    case Tesla.get(client, url, conn: conn) do
      {:ok, res} ->
        response_to_map(res, url, time) |> IO.inspect()

      {:error, err} ->
        response_fail(err)
    end
  end

  """
    Example of request function

    request(client, :post, params, time, conn)
    request(client, :put, params, time, conn)
    request(client, :delete, params, time, conn)
    request(client, :patch, params, time, conn)
  """

  def request(client, method, params, time, conn) do
    [_, url, body, headers] = params

    case method do
      :post -> handle_post(client, url, body, headers, conn)
      _ -> handle_request(method, client, url, body, conn)
    end
    |> handle_response(url, time)
  end

  defp handle_post(client, url, body, headers, conn) do
    case Map.get(headers, "Content-Type") do
      "multipart/form-data" ->
        file_path = Enum.find_value(body, fn {_, v} -> if File.exists?(v), do: v, else: nil end)

        if file_path do
          multipart_data = build_multipart_data(file_path)
          Tesla.post(client, url, multipart_data, conn: conn)
        else
          Tesla.post(client, url, body, conn: conn)
        end

      "application/x-www-form-urlencoded" ->
        encoded_body = Tesla.encode_query(body)
        Tesla.post(client, url, encoded_body, conn: conn)

      _ ->
        Tesla.post(client, url, body, conn: conn)
    end
  end

  defp handle_request(method, client, url, body, conn) do
    Tesla.request(client, method, url, body, conn: conn)
  end

  defp handle_response({:ok, res}, url, time) do
    response_to_map(res, url, time) |> IO.inspect()
  end

  defp handle_response({:error, err}, _, _) do
    response_fail(err)
  end

  ### common functions

  defp response_to_map(response, url, time) do
    [start, conn_time] = time

    %{
      status: response.status,
      headers: response.headers,
      body: response.body,
      label: "sample",
      thread_name: "#{inspect(self())}",
      url: url,
      sent_bytes: String.length(response.body),
      connect: conn_time
      # concurrency: concurrency
    }
  end

  defp response_fail(res) do
    IO.puts("Hubo un error en la petición, el error fue #{res}")
    IO.inspect(System.stacktrace())
  end

  defp options_mint(scheme) do
    case scheme do
      :https -> [transport_opts: [verify: :verify_none, timeout: 60000]]
      :http -> [transport_opts: [timeout: 60000]]
      _ -> []
    end
  end

  defp build_multipart_data(file_path) when is_binary(file_path) do
    Multipart.new() |> Multipart.add_file(file_path)
  end
end
