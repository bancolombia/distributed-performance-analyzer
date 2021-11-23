defmodule DatasetTest do
  use ExUnit.Case
  doctest Dataset

  import ExUnit.CaptureLog
  require Logger

  test "test logger" do
    assert catch_error(Dataset.parse_csv("dummy", ";"))
  end
end
