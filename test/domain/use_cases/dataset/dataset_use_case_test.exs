defmodule DistributedPerformanceAnalyzer.Test.Domain.UseCase.Dataset.DatasetUseCaseTest do
  use ExUnit.Case, async: true

  alias DistributedPerformanceAnalyzer.Domain.UseCase.Dataset.DatasetUseCase

  @sample_data [
    %{number: "1234567890", type: "CC"},
    %{number: "1234567890", type: "NIT"},
    %{number: "1234567890", type: "TI"}
  ]

  #  test "parse file that doesn't exists" do
  #    #    Arrange
  #    path = "dummy"
  #    separator = ";"
  #
  #    # Act
  #    result = DatasetUseCase.parse(path, separator)
  #
  #    # Assert
  #    assert result == {:error, "Dataset file #{path} not found"}
  #  end
  #
  #  test "parse file without valid extension" do
  #    #    Arrange
  #    path = "test/domain/use_cases/dataset/datasets/sample.txt"
  #    separator = ";"
  #
  #    # Act
  #    result = DatasetUseCase.parse(path, separator)
  #
  #    # Assert
  #    assert result == {:error, "Dataset file #{path} does not have a valid extension"}
  #  end
  #
  #  test "parse csv" do
  #    #    Arrange
  #    path = "test/domain/use_cases/dataset/datasets/sample1.csv"
  #    separator = ","
  #
  #    # Act
  #    result = DatasetUseCase.parse(path, separator)
  #
  #    # Assert
  #    assert result == {:ok, @sample_data}
  #  end

  #  test "parse csv without default separator" do
  #    #    Arrange
  #    path = "test/domain/use_cases/dataset/datasets/sample2.csv"
  #    separator = ";"
  #
  #    # Act
  #    result = DatasetUseCase.parse(path, separator)
  #
  #    # Assert
  #    assert result == {:ok, @sample_data}
  #  end

  #  test "get random item when list is empty" do
  #    #    Arrange
  #    list = []
  #
  #    # Act
  #    result = DatasetUseCase.get_random_item(list)
  #
  #    # Assert
  #    assert result == nil
  #  end
  #
  #  test "get random item from list" do
  #    #    Arrange
  #    list = [1, 2, 3, 4, 5]
  #
  #    # Act
  #    result = DatasetUseCase.get_random_item(list)
  #
  #    # Assert
  #    assert result in list
  #  end

  test "replace empty value" do
    #    Arrange
    value = ~s|Hello World|

    # Act
    result = DatasetUseCase.replace_value(value, nil)

    # Assert
    assert result == value
  end

  test "replace value in function" do
    #    Arrange
    value = fn item -> ~s|Hello world from #{item.value}| end
    item = %{value: "test"}

    # Act
    result = DatasetUseCase.replace_value(value, item)

    # Assert
    assert result == ~s|Hello world from test|
  end

  test "replace value in map" do
    #    Arrange
    value = ~s|Hello world from {name}|
    item = %{"name" => "test"}

    # Act
    result = DatasetUseCase.replace_value(value, item)

    # Assert
    assert result == ~s|Hello world from test|
  end

  test "replace value in list" do
    #    Arrange
    value = fn item ->
      [{"Content-Type", ~s|#{item.content_type}|}, {"Content-Length", ~s|#{item.content_length}|}]
    end

    item = %{content_type: "application/json", content_length: "100"}

    # Act
    result = DatasetUseCase.replace_value(value, item)

    # Assert
    assert result == [{"Content-Type", "application/json"}, {"Content-Length", "100"}]
  end
end
