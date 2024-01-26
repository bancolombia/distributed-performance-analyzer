defmodule DistributedPerformanceAnalyzer.Infrastructure.Adapters.JMeter.Parser do
  @moduledoc """
  Provides functions for parsing JMeter results
  """

  alias DistributedPerformanceAnalyzer.Domain.Model.Config.Response
  alias DistributedPerformanceAnalyzer.Domain.Model.User
  alias DistributedPerformanceAnalyzer.Utils.DataTypeUtils

  @behaviour Parser

  #  Template: "timeStamp,elapsed,label,responseCode,responseMessage,threadName,dataType,success,failureMessage,bytes,sentBytes,grpThreads,allThreads,URL,Latency,IdleTime,Connect",

  @impl true
  def parse(%Response{} = response) do
    %{
      status: status,
      message: message,
      headers: headers,
      elapsed: elapsed,
      timestamp: timestamp,
      connection_time: connection_time,
      content_type: content_type,
      received_bytes: received_bytes
    } = response

    label = ""
    response_code = ""
    response_message = ""
    thread_name = ""
    data_type = ""
    success = ""
    failure_message = ""
    bytes = ""
    sent_bytes = ""
    grp_threads = ""
    all_threads = ""
    url = ""
    latency = ""
    idle_time = ""
    connect = ""

    #    TODO: complete info
    result =
      ~s|#{elapsed},#{label},#{response_code},#{sanitize(response_message)},#{thread_name},#{data_type},#{success},#{sanitize(failure_message)},#{bytes},#{sent_bytes},#{grp_threads},#{all_threads},#{url},#{latency},#{idle_time},#{connect}|

    {:ok, {timestamp, result}}
  end

  defp sanitize(input), do: String.replace(input, ",", ";")
end
