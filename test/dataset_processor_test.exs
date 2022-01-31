defmodule DatasetTest do
  use ExUnit.Case
  doctest Dataset

  require Logger

  test "no such file or directory" do
    assert catch_error(Dataset.parse_csv("dummy", ";"))
  end

  test "parse csv" do
    sample_csv = [
      %{number: "1234567890", type: "CC"},
      %{number: "1234567890", type: "NIT"},
      %{number: "1234567890", type: "TI"}
    ]

    data = Dataset.parse_csv("test/sample1.csv", ",")
    IO.inspect(data)
    assert data == sample_csv
  end

  test "parse csv without default separator" do
    sample_csv = [
      %{number: "1234567890", type: "CC"},
      %{number: "1234567890", type: "NIT"},
      %{number: "1234567890", type: "TI"}
    ]
    
    data = Dataset.parse_csv("test/sample2.csv", ";")
    IO.inspect(data)
    assert data == sample_csv
  end
end
