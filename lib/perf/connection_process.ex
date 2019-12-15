defmodule Perf.ConnectionProcess do
  use GenServer

  require Logger

  defstruct [:conn, :params, requests: %{}]

  def start_link({scheme, host, port}) do
    {:ok, pid} = GenServer.start_link(__MODULE__, {scheme, host, port})
    send(pid, :late_init)
    {:ok, pid}
  end

  def request(pid, method, path, headers, body) do
    GenServer.call(pid, {:request, method, path, headers, body})
  end

  def invoke(pid) do
    init_time = :erlang.monotonic_time(:milli_seconds)
    result = request(pid, "GET", "/rest/appInfo/version", [], "")
    total_time = :erlang.monotonic_time(:milli_seconds) - init_time
    {total_time, result}
  end

  ## Callbacks

  @impl true
  def init({scheme, host, port}) do
    state = %__MODULE__{conn: nil, params: {scheme, host, port}}
    {:ok, state}
  end

  @impl true
  def handle_info(:late_init, state = %__MODULE__{params: {scheme, host, port}}) do
    case Mint.HTTP.connect(scheme, host, port) do
      {:ok, conn} -> {:noreply, put_in(state.conn, conn)}
      {:error, _} -> {:noreply, state}
    end
  end

  @impl true
  def handle_call({:request, _, _, _, _}, _, state = %__MODULE__{conn: nil}) do
    send(self(), :late_init)
    Process.sleep(300)
    {:reply, {:error, :invalid_connection}, state}
  end

  @impl true
  def handle_call({:request, method, path, headers, body}, from, state) do
    # In both the successful case and the error case, we make sure to update the connection
    # struct in the state since the connection is an immutable data structure.
    case Mint.HTTP.request(state.conn, method, path, headers, body) do
      {:ok, conn, request_ref} ->
        state = put_in(state.conn, conn)
        # We store the caller this request belongs to and an empty map as the response.
        # The map will be filled with status code, headers, and so on.
        state = put_in(state.requests[request_ref], %{from: from, response: %{}})
        {:noreply, state}

      {:error, conn, reason} ->
        state = put_in(state.conn, conn)
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_info(message, state) do
    # We should handle the error case here as well, but we're omitting it for brevity.
    case Mint.HTTP.stream(state.conn, message) do
      :unknown ->
        _ = Logger.error(fn -> "Received unknown message: " <> inspect(message) end)
        {:noreply, state}

      {:ok, conn, responses} ->
        state = put_in(state.conn, conn)
        state = Enum.reduce(responses, state, &process_response/2)
        {:noreply, state}

        {:error, conn, reason, responses} ->
          Logger.error(fn -> "Received error message: " <> inspect(reason) end)
          {scheme, host, port} = state.params
          {:ok, new_conn} = Mint.HTTP.connect(scheme, host, port)
          state = put_in(state.conn, new_conn)
          {:noreply, state}
    end
  end

  defp process_response({:status, request_ref, status}, state) do
    put_in(state.requests[request_ref].response[:status], status)
  end

  defp process_response({:headers, request_ref, headers}, state) do
    put_in(state.requests[request_ref].response[:headers], headers)
  end

  defp process_response({:data, request_ref, new_data}, state) do
    update_in(state.requests[request_ref].response[:data], fn data -> (data || "") <> new_data end)
  end

  # When the request is done, we use GenServer.reply/2 to reply to the caller that was
  # blocked waiting on this request.
  defp process_response({:done, request_ref}, state) do
    {%{response: response, from: from}, state} = pop_in(state.requests[request_ref])
    GenServer.reply(from, {:ok, response})
    state
  end

end
