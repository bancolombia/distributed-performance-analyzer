defmodule DistributedPerformanceAnalyzer.Infrastructure.EntryPoints.DpaRouter do
  @moduledoc """
  HTTP polling endpoint for DPA events.

  Routes:
    GET /health            — liveness probe: {"status":"ok"}
    GET /events            — returns all buffered events
    GET /events?since=<ms> — returns events with timestamp >= since_ms (Unix ms)
  """

  use Plug.Router

  alias DistributedPerformanceAnalyzer.Infrastructure.EntryPoints.LogBuffer

  plug CORSPlug
  plug :match
  plug :dispatch

  get "/health" do
    send_json(conn, 200, %{status: "ok"})
  end

  get "/events" do
    conn = Plug.Conn.fetch_query_params(conn)
    since_ms = parse_since(conn.query_params["since"])

    events =
      if since_ms == 0,
        do: LogBuffer.get_all(),
        else: LogBuffer.get_since(since_ms)

    send_json(conn, 200, %{events: events})
  end

  match _ do
    send_resp(conn, 404, "not found")
  end

  defp send_json(conn, status, body) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(body))
  end

  defp parse_since(nil), do: 0

  defp parse_since(val) do
    case Integer.parse(val) do
      {n, _} -> max(n, 0)
      :error -> 0
    end
  end
end
