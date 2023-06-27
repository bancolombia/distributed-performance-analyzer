defmodule DistributedPerformanceAnalyzer.Domain.Model.RequestResultTest do
  use ExUnit.Case

  describe "new/5" do
    test "creates a new RequestResult struct" do
      label = "Test Request"
      thread_name = "Test Thread"
      url = "http://example.com"
      sent_bytes = 100
      connect = 50

      result = RequestResult.new(label, thread_name, url, sent_bytes, connect)

      assert %RequestResult{
        start: _,
        time_stamp: _,
        label: ^label,
        thread_name: ^thread_name,
        url: ^url,
        sent_bytes: ^sent_bytes,
        connect: ^connect,
        elapsed: 0,
        response_code: 0,
        response_message: "",
        data_type: "",
        success: false,
        failure_message: "",
        bytes: 0,
        latency: 0,
        idle_time: 0,
        response_headers: []
      } = result
    end
  end
 end
