defmodule DistributedPerformanceAnalyzer.Domain.Model.LoadGeneratorConfigTest do
  use ExUnit.Case

  describe "new/2" do
    test "creates a new LoadGeneratorConfig struct" do
      method = "GET"
      path = "/api/test"

      config = LoadGeneratorConfig.new(method, path)

      assert %LoadGeneratorConfig{
        method: ^method,
        path: ^path,
        headers: [],
        body: ""
      } = config
    end
  end
 end
