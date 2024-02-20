defmodule DistributedPerformanceAnalyzer.Infrastructure.Adapters.Http.HttpClient do
  require Logger

  @moduledoc """
  Provides functions for making HTTP requests
  """
  use Tesla
  adapter(Tesla.Adapter.Mint)

  alias Tesla.Multipart
  alias DistributedPerformanceAnalyzer.Domain.Behaviours.Request.HttpClient
  alias DistributedPerformanceAnalyzer.Domain.Model.{Config.Request, Config.Response}
  alias DistributedPerformanceAnalyzer.Utils.DataTypeUtils

  @behaviour HttpClient

  @client Tesla.client([], Tesla.Adapter.Mint)
  @content_type "content-type"
  @content_length "content-length"
  @form_data "multipart/form-data"
  @form_urlencoded "application/x-www-form-urlencoded"

  @impl true
  def open_connection(%Request{url: url, timeout: timeout, ssl: ssl}) do
    start_time = DataTypeUtils.start_time()
    %{host: host, port: port, scheme: scheme} = DataTypeUtils.parse_url(url)

    case Mint.HTTP.connect(scheme, host, port, mint_opts(scheme, ssl, timeout)) do
      {:ok, connection} ->
        {:ok,
         connection |> Map.merge(%{time: DataTypeUtils.duration_time(start_time), reused: false})}

      error ->
        error
    end
  end

  @impl true
  def close_connection(connection) do
    Mint.HTTP.close(connection)
    :ok
  end

  @impl true
  def do_request(
        connection,
        %Request{
          method: method,
          url: url,
          body: body,
          headers: headers
        } = request
      ) do
    start_time = DataTypeUtils.start_time()

    response =
      handle_request(@client, method, url, headers, body, connection)
      |> handle_response(request, connection, start_time)

    {:ok,
     %{
       response: response,
       connection: update_connection_state(connection)
     }}
  end

  defp handle_request(client, :post, url, headers, body, conn) do
    request_body =
      case DataTypeUtils.extract_header(headers, @content_type) do
        {:ok, @form_data} ->
          file_path = Enum.find_value(body, fn {_, v} -> if File.exists?(v), do: v, else: nil end)
          if file_path, do: build_multipart_data(file_path), else: body

        {:ok, @form_urlencoded} ->
          Tesla.encode_query(body)

        _ ->
          body
      end

    Tesla.post(client, url, request_body, headers: headers, conn: conn)
  end

  defp handle_request(client, method, url, headers, body, conn),
    do: Tesla.request(client, method: method, url: url, headers: headers, body: body, conn: conn)

  defp handle_response({:ok, res}, %Request{} = request, connection, start_time),
    do: parse_response(res, request, connection, start_time)

  defp handle_response({:error, err}, _, _, _), do: fail_response(err)

  defp parse_response(
         %Tesla.Env{status: status, headers: headers, body: body},
         %Request{} = _request,
         %{time: time, reused: reused} = _connection,
         start_time
       ) do
    Response.new(%{
      status: status,
      message: body,
      elapsed: DataTypeUtils.duration_time(start_time),
      timestamp: DataTypeUtils.timestamp(),
      connection_time: if(reused, do: 0, else: time),
      content_type: DataTypeUtils.extract_header!(headers, @content_type),
      received_bytes:
        DataTypeUtils.extract_header!(headers, @content_length) |> DataTypeUtils.parse_to_int()
    })
  end

  #  TODO: Send error reason
  defp fail_response(res), do: Logger.warning("Request error: #{res}")

  defp mint_opts(scheme, ssl_validation, timeout) do
    #    TODO: enable cacerts https://hexdocs.pm/mint/Mint.HTTP.html#module-ssl-certificates
    verify = if ssl_validation, do: :verify_peer, else: :verify_none

    case scheme do
      :https -> [transport_opts: [verify: verify, timeout: timeout]]
      :http -> [transport_opts: [timeout: timeout]]
      _ -> []
    end
  end

  defp build_multipart_data(file_path) when is_binary(file_path),
    do: Multipart.new() |> Multipart.add_file(file_path)

  defp update_connection_state(%{reused: reused} = connection),
    do: if(reused, do: connection, else: Map.put(connection, :reused, true))
end
