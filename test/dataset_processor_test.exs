defmodule DatasetTest do
  use ExUnit.Case
  doctest Dataset

  require Logger

  test "no such file or directory" do
    assert catch_error(Dataset.parse_csv("dummy", ";"))
  end
end
