defmodule DistributedPerformanceAnalyzer.Domain.UseCase.ConnectionProcessUseCase do
  @moduledoc """
  Connection process use case.

  url connection handler
  """

  use GenServer
  require Logger
  alias DistributedPerformanceAnalyzer.Domain.Model.{ConnectionProcess, RequestResult}
  alias DistributedPerformanceAnalyzer.Domain.UseCase.RequestResultUseCase
  alias DistributedPerformanceAnalyzer.Utils.DataTypeUtils

  # defstruct [:conn, :params, :conn_time, request: %{}]

  def start_link({scheme, host, port, id}) do
    {:ok, pid} = GenServer.start_link(__MODULE__, {scheme, host, port}, name: id)
    send(pid, :late_init)
    {:ok, pid}
  end

  def request(pid, method, path, headers, body, concurrency) do
    Logger.debug(%{method: method, path: path, headers: headers, body: body})

    :timer.tc(fn ->
      GenServer.call(pid, {:request, method, path, headers, body, concurrency}, 60_000)
    end)
  end

  ## Callbacks

  @impl true
  def init({scheme, host, port}) do
    state = %ConnectionProcess{conn: nil, params: {scheme, host, port}}
    {:ok, state}
  end

  @compile {:inline, options: 1}
  defp options(:https) do
    [transport_opts: [verify: :verify_none, timeout: 60000]]
  end

  defp options(:http) do
    [transport_opts: [timeout: 60000]]
  end

  @impl true
  def handle_call({:request, _, _, _, _}, _, state = %ConnectionProcess{conn: nil}) do
    send(self(), :late_init)
    Process.sleep(200)
    {:reply, {:nil_conn, "Invalid connection state: nil"}, state}
  end

  @impl true
  def handle_call({:request, method, path, headers, body, concurrency}, from, state) do
    {:ok, response} =
      RequestResult.new(
        label: "sample",
        thread_name: "#{inspect(self())}",
        url: get_endpoint(state.conn, path, method),
        sent_bytes: String.length(body),
        connect: state.conn_time,
        concurrency: concurrency
      )

    start = :erlang.monotonic_time(:millisecond)

    case Mint.HTTP.request(state.conn, method, path, parse_headers(headers), body) do
      {:ok, conn, request_ref} ->
        conn_time = :erlang.monotonic_time(:millisecond) - start

        state = %{
          state
          | conn: conn,
            conn_time: conn_time,
            request: %{
              from: from,
              response: response,
              ref: request_ref,
              status: nil,
              headers: [],
              body: "",
              latency: 0
            }
        }

        {:noreply, state}

      {:error, conn, reason} ->
        state = put_in(state.conn, conn)
        send(self(), :late_init)
        {:reply, {:error_conn, reason}, state}
    end
  end

  @impl true
  def handle_info(:late_init, state = %ConnectionProcess{params: {scheme, host, port}}) do
    start = :erlang.monotonic_time(:millisecond)

    case Mint.HTTP.connect(scheme, host, port, options(scheme)) do
      {:ok, conn} ->
        {:noreply, %{state | conn: conn, conn_time: :erlang.monotonic_time(:millisecond) - start}}

      {:error, err} ->
        Logger.warning(
          "Error creating connection with #{inspect({scheme, host, port})}: #{inspect(err)}"
        )

        {:noreply, state}
    end
  end

  @impl true
  def handle_info(message, state = %ConnectionProcess{conn: nil}) do
    Logger.warning(fn -> "Received message with null conn: " <> inspect(message) end)
    {:noreply, state}
  end

  @impl true
  def handle_info(message, state) do
    case Mint.HTTP.stream(state.conn, message) do
      :unknown ->
        Logger.warning(fn -> "Received unknown message: " <> inspect(message) end)
        {:noreply, state}

      {:ok, conn, []} ->
        {:noreply, put_in(state.conn, conn)}

      {:ok, conn, responses} ->
        Logger.debug(responses)
        state = put_in(state.conn, conn)
        state = Enum.reduce(responses, state, process_response_fn(state))
        {:noreply, state}

      {:error, _conn, reason, _responses} ->
        #        Logger.error(reason)
        case state.request do
          %{from: from, ref: _request_ref} -> GenServer.reply(from, {:protocol_error, reason})
          _ -> nil
        end

        {:noreply, put_in(state.conn, nil)}
    end
  end

  defp process_response_fn(%ConnectionProcess{request: %{ref: original_ref}}) do
    fn message, state ->
      case message do
        {:status, ^original_ref, status} -> set_latency(state, :status, status)
        {:done, ^original_ref} -> process_response(message, state)
        {:headers, ^original_ref, headers} -> set_latency(state, :headers, headers)
        {:data, ^original_ref, data} -> set_latency(state, :body, data <> state.request.body)
        {:error, ^original_ref, _reason} -> process_response(message, state)
        _ -> state
      end
    end
  end

  defp set_latency(state, item, value) do
    new_state = put_in(state.request[item], value)

    if new_state.request.latency == 0 do
      put_in(new_state.request.latency, :erlang.monotonic_time(:millisecond))
    else
      new_state
    end
  end

  defp process_response(
         {:done, _request_ref},
         state = %ConnectionProcess{
           request: %{
             from: from,
             status: status,
             body: body,
             headers: headers,
             latency: latency,
             response: response
           }
         }
       ) do
    # IO.puts("Done request!")

    received_bytes = DataTypeUtils.extract_header!(headers, "content-length")
    content_type = DataTypeUtils.extract_header!(headers, "content-type")

    final_result =
      RequestResultUseCase.complete(response, status, body, received_bytes, content_type, latency)

    GenServer.reply(from, {status_for(status), final_result})
    %{state | request: %{}}
  end

  defp process_response(
         {:error, _request_ref, reason},
         state = %ConnectionProcess{request: %{from: from, init: _init}}
       ) do
    GenServer.reply(from, {:protocol_error, reason})
    Logger.error(reason)
    %{state | request: %{}}
  end

  defp status_for(status) when status >= 200 and status < 300, do: :ok
  defp status_for(status) when status >= 300 and status < 400, do: :redirect
  defp status_for(status) when status >= 400 and status < 500, do: :bad_request
  defp status_for(status) when status >= 500, do: :server_error
  defp status_for(_status), do: :fail_http

  defp get_endpoint(%{hostname: hostname, scheme: scheme, port: port}, url, method) do
    "#{method} -> #{scheme}://#{hostname}:#{port}#{get_path(url)}"
  end

  defp get_endpoint(%{host: hostname, scheme_as_string: scheme, port: port}, url, method) do
    "#{method} -> #{scheme}://#{hostname}:#{port}#{get_path(url)}"
  end

  defp get_path(url) do
    %{path: path} = DataTypeUtils.parse_url(url)
    path
  end

  defp parse_headers(headers_list) when is_list(headers_list) do
    headers_list
    |> Enum.map(fn {key, value} ->
      if is_atom(key), do: {Atom.to_string(key), value}
    end)
  end
end
