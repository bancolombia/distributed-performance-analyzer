defmodule DatasetTest do
  use ExUnit.Case
  doctest Dataset

  require Logger

  @sample_data [
    %{number: "1234567890", type: "CC"},
    %{number: "1234567890", type: "NIT"},
    %{number: "1234567890", type: "TI"}
  ]

  test "no such file or directory" do
    assert catch_error(Dataset.parse_csv("dummy", ";"))
  end

  test "parse csv" do
    data = Dataset.parse_csv("test/perf/dataset/sample1.csv", ",")
    assert data == @sample_data
  end

  test "parse csv without default separator" do
    data = Dataset.parse_csv("test/perf/dataset/sample2.csv", ";")
    assert data == @sample_data
  end

end
