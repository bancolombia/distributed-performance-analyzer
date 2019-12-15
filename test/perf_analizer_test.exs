defmodule PerfAnalizerTest do
  use ExUnit.Case
  doctest PerfAnalizer

  test "greets the world" do
    assert PerfAnalizer.hello() == :world
  end
end
