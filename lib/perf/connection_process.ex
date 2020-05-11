defmodule Perf.ConnectionProcess do
  use GenServer

  require Logger

  defstruct [:conn, :params, request: %{}]

  def start_link({scheme, host, port, id}) do
    {:ok, pid} = GenServer.start_link(__MODULE__, {scheme, host, port}, name: id)
    send(pid, :late_init)
    {:ok, pid}
  end

  def request(pid, method, path, headers, body) do
    :timer.tc(fn  ->
      GenServer.call(pid, {:request, method, path, headers, body})
    end)
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
      {:ok, conn} -> {:noreply, %{state | conn: conn}}
      {:error, _} -> {:noreply, state}
    end
  end


  @impl true
  def handle_call({:request, _, _, _, _}, _, state = %__MODULE__{conn: nil}) do
    #Logger.error(fn -> "Invalid connection state: nil" end)
    send(self(), :late_init)
    Process.sleep(200)
    {:reply, {:nil_conn, "Invalid connection state: nil"}, state}
  end

  @impl true
  def handle_call({:request, method, path, headers, body}, from, state) do
    init_time = :erlang.monotonic_time(:micro_seconds)
    case Mint.HTTP.request(state.conn, method, path, headers, body) do
      {:ok, conn, request_ref} ->
        state = %{state | conn: conn, request: %{from: from, response: %{}, ref: request_ref, status: nil, init: init_time}}
        {:noreply, state}

      {:error, conn, reason} ->
        state = put_in(state.conn, conn)
        send(self(), :late_init)
        {:reply, {:error_conn, reason}, state}
    end
  end

  @impl true
  def handle_info(message, state) do
    case Mint.HTTP.stream(state.conn, message) do
      :unknown ->
        Logger.error(fn -> "Received unknown message: " <> inspect(message) end)
        {:noreply, state}

      {:ok, conn, responses} ->
        state = put_in(state.conn, conn)
        state = Enum.reduce(responses, state, process_response_fn(state))
        {:noreply, state}

      {:error, conn, reason, responses} ->
        case state.request do
          %{from: from, ref: request_ref} -> GenServer.reply(from, {:protocol_error, reason})
          _ -> nil
        end
        {:noreply, put_in(state.conn, nil)}
    end
  end

  defp process_response_fn(%__MODULE__{request: %{ref: original_ref}}) do
    fn (message, state) ->
      case message do
        {:status, ^original_ref, status} -> put_in(state.request.status, status)
        {:done, ^original_ref} -> process_response(message, state)
        _ -> state
      end
    end
  end


  defp process_response({:done, _request_ref}, state = %__MODULE__{request: %{from: from, init: init, status: status}}) do
    GenServer.reply(from, {status_for(status), :erlang.monotonic_time(:micro_seconds) - init})
    %{state | request: %{}}
  end

  defp status_for(status) when status >= 200 and status < 400, do: :ok
  defp status_for(status), do: {:fail_http, status}


end