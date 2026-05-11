defmodule DistributedPerformanceAnalyzer.Domain.UseCase.ConnectionProcessUseCaseTest do
  use ExUnit.Case, async: true

  alias DistributedPerformanceAnalyzer.Domain.UseCase.ConnectionProcessUseCase

  @method "POST"
  @path "/some/path"
  @headers [{"Content-Type", "application/json"}]
  @body "{}"

  describe "handle_call {:request, ...} when conn is nil" do
    setup do
      name = :"conn_process_#{System.unique_integer([:positive])}"

      {:ok, pid} =
        GenServer.start_link(ConnectionProcessUseCase, {:http, "localhost", 9999}, name: name)

      {:ok, pid: pid}
    end

    test "returns {:nil_conn, _} instead of crashing when conn is nil", %{pid: pid} do
      result = GenServer.call(pid, {:request, @method, @path, @headers, @body, 1}, 5_000)
      assert {:nil_conn, message} = result
      assert is_binary(message)
    end

    test "reply includes descriptive message when conn is nil", %{pid: pid} do
      {:nil_conn, message} =
        GenServer.call(pid, {:request, @method, @path, @headers, @body, 5}, 5_000)

      assert message =~ "nil"
    end
  end
end
