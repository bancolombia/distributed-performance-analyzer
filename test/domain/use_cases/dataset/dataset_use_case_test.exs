defmodule DistributedPerformanceAnalyzer.Test.Domain.UseCase.Dataset.DatasetUseCaseTest do
  use ExUnit.Case

  alias DistributedPerformanceAnalyzer.Domain.UseCase.Dataset.DatasetUseCase

  test "get random item when list is empty" do
    #    Arrange
    list = []

    # Act
    result = DatasetUseCase.get_random_item(list)

    # Assert
    assert result == nil
  end

  test "get random item from list" do
    #    Arrange
    list = [1, 2, 3, 4, 5]

    # Act
    result = DatasetUseCase.get_random_item(list)

    # Assert
    assert result in list
  end

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
