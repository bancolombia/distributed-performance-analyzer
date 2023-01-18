defmodule DistributedPerformanceAnalyzer.Infrastructure.EntryPoint.ApiRest do

  @moduledoc """
  Access point to the rest exposed services
  """
  alias DistributedPerformanceAnalyzer.Utils.DataTypeUtils
  alias DistributedPerformanceAnalyzer.Infrastructure.EntryPoint.ErrorHandler
  require Logger
  use Plug.Router
  use Timex

  plug(CORSPlug,
    methods: ["GET", "POST", "PUT", "DELETE"],
    origin: [~r/.*/],
    headers: ["Content-Type", "Accept", "User-Agent"]
  )

  plug(Plug.Logger, log: :debug)
  plug(:match)
  plug(Plug.Parsers, parsers: [:urlencoded, :json], json_decoder: Poison)
  plug(Plug.Telemetry, event_prefix: [:distributed_performance_analyzer, :plug])
  plug(:dispatch)

  forward(
    "/distributed_performance_analyzer/api/health",
    to: PlugCheckup,
    init_opts: PlugCheckup.Options.new(json_encoder: Jason, checks: DistributedPerformanceAnalyzer.Infrastructure.EntryPoint.HealthCheck.checks)
  )

  get "/distributed_performance_analyzer/api/hello/" do
    build_response("Hello World", conn)
  end


  def build_response(%{status: status, body: body}, conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Poison.encode!(body))
  end

  def build_response(response, conn), do: build_response(%{status: 200, body: response}, conn)

  match _ do
    conn
    |> handle_not_found(Logger.level())
  end

  defp handle_error(error, conn) do
    error
    |> ErrorHandler.build_error_response()
    |> build_response(conn)
  end

  defp handle_bad_request(error, conn) do
    error
    |> ErrorHandler.build_error_response()
    |> build_bad_request_response(conn)
  end

  defp build_bad_request_response(response, conn) do
    build_response(%{status: 400, body: response}, conn)
  end

  defp handle_not_found(conn, :debug) do
    %{request_path: path} = conn
    body = Poison.encode!(%{status: 404, path: path})
    send_resp(conn, 404, body)
  end

  defp handle_not_found(conn, _level) do
    send_resp(conn, 404, "")
  end
end
