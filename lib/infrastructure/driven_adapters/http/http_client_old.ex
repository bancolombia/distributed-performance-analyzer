defmodule DistributedPerformanceAnalyzer.Infrastructure.Adapters.Http.HttpClientOld do
  use GenServer

  require Logger

  defstruct [:conn, :params, :conn_time, request: %{}]

  @moduledoc """
  Provides functions for making HTTP requests and GenServer Process.
  """

  @doc """
    GenServer
  """

  def start_link({scheme, host, port, id}) do
    {:ok, pid} = GenServer.start_link(__MODULE__, {scheme, host, port}, name: id)
    send(pid, :late_init)
    {:ok, pid}
  end

  @impl true
  def init({scheme, host, port}) do
    state = %__MODULE__{conn: nil, params: {scheme, host, port}}
    {:ok, state}
  end

  def request(pid, method, path, headers, body) do
    :timer.tc(fn ->
      GenServer.call(pid, {:request, method, path, headers, body}, 15_000)
    end)
  end

  # Latency HTTP
  defp set_latency(state, item, value) do
    new_state = put_in(state.request[item], value)

    # If the value is 0, start latency measurement by setting the latency to the current time
    if new_state.request.latency == 0,
      do: put_in(new_state.request.latency, :erlang.monotonic_time(:millisecond)),
      else: new_state
  end

  # Connect Mint HTTP
  @impl true
  def handle_info(:late_init, state = %__MODULE__{params: {scheme, host, port}}) do
    start = :erlang.monotonic_time(:millisecond)

    case Mint.HTTP.connect(scheme, host, port, options(scheme)) do
      {:ok, conn} ->
        conn_time = :erlang.monotonic_time(:millisecond) - start
        new_state = %{state | conn: conn, conn_time: conn_time}
        {:noreply, new_state}

      {:error, err} ->
        Logger.error(
          "Error creating connection with #{inspect({scheme, host, port})}: #{inspect(err)}"
        )

        {:noreply, state}
    end
  end

  # Stream Mint HTTP
  @impl true
  def handle_info(message, state) do
    case Mint.HTTP.stream(state.conn, message) do
      :unknown ->
        Logger.warning(fn -> "Received unknown message: " <> inspect(message) end)
        {:noreply, state}

      {:ok, conn, []} ->
        {:noreply, put_in(state.conn, conn)}

      {:ok, conn, responses} ->
        state = put_in(state.conn, conn)
        state = Enum.reduce(responses, state, process_response_fn(state))
        {:noreply, state}

        # Check if the HTTP connection is open using Mint.HTTP.open?/1
        if Mint.HTTP.open?(state.conn),
          do: {:noreply, state},
          else: {:noreply, put_in(state.conn, nil)}

      # Notify the originating process with a protocol error message if valid,
      {:error, _conn, reason, _responses} ->
        Logger.error(
          "Encountered error when streaming responses, reason: " <> Exception.message(reason)
        )

        case Map.get(state.request, :from) do
          from when is_pid(from) -> GenServer.reply(from, {:protocol_error, reason})
          _ -> nil
        end

        {:noreply, put_in(state.conn, nil)}
    end
  end

  # Request Mint HTTP
  @impl true
  def handle_call({:request, method, path, headers, body}, from, state) do
    response =
      RequestResult.new(
        "sample",
        "#{inspect(self())}",
        get_endpoint(state.conn, path, method),
        String.length(body),
        state.conn_time
      )

    # IO.puts "Making Request!"
    start = :erlang.monotonic_time(:millisecond)

    case Mint.HTTP.request(state.conn, method, path, headers, body) do
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

  # Process GenServer
  defp process_response_fn(%__MODULE__{request: %{ref: original_ref}}) do
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

  defp process_response(
         {:done, _request_ref},
         state = %__MODULE__{
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
    final_result = RequestResult.complete(response, status, body, headers, latency)
    GenServer.reply(from, {status_for(status), final_result})
    %{state | request: %{}}
  end

  defp process_response(
         {:error, _request_ref, reason},
         state = %__MODULE__{request: %{from: from, init: _init}}
       ) do
    GenServer.reply(from, {:protocol_error, reason})
    # IO.puts("Request error")
    IO.inspect(reason)
    %{state | request: %{}}
  end

  defp status_for(status) when status >= 200 and status < 400, do: :ok
  defp status_for(status), do: {:fail_http, status}

  defp get_endpoint(%{hostname: hostname, scheme: scheme, port: port}, path, method) do
    "#{method} -> #{scheme}://#{hostname}:#{port}#{path}"
  end

  defp get_endpoint(%{host: hostname, scheme_as_string: scheme, port: port}, path, method) do
    "#{method} -> #{scheme}://#{hostname}:#{port}#{path}"
  end

  @compile {:inline, options: 1}
  defp options(:https) do
    [transport_opts: [verify: :verify_none]]
  end

  defp options(:http) do
    []
  end
end

defmodule Tesla.HTTP do
  use Tesla
  alias Tesla.Multipart

  @doc """
  Perform an HTTP request with support for 'multipart' data format.

  ## Parameters

  - `url`: The URL to which the request will be made.
  - `file_path`: The path of the file to be sent as part of the 'multipart' form.
  - `timeout`: The timeout for the HTTP request in milliseconds.

  ## Example

      Tesla.HTTP.request("https://httpbin.com/post", "/path/to/file.txt", 5000)

  """
  def request(url, file_path, timeout)
      when is_binary(url) and is_binary(file_path) and is_integer(timeout) do
    middleware = [
      {Tesla.Middleware.Logger, debug: false},
      {Tesla.Middleware.Timeout, timeout: timeout}
    ]

    client = Tesla.client(middleware, Tesla.Adapter.Mint)
    multipart = build_multipart_data(file_path)

    case Tesla.post(client, url, multipart) do
      {:ok, response} ->
        {:ok, response.status}

      {:error, reason} ->
        {:error, "HTTP request error: #{inspect(reason)}"}
    end
  end

  defp build_multipart_data(file_path) when is_binary(file_path) do
    Multipart.new() |> Multipart.add_file(file_path)
  end
end
