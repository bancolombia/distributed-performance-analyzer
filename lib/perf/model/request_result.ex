defmodule RequestResult do
  defstruct [
    start: 0,
    time_stamp: 0,
    label: "",
    thread_name: "",
    grp_threads: 0,
    all_threads: 1,
    url: "",
    elapsed: 0,
    response_code: 0,
    response_message: "",
    data_type: "",
    success: false,
    failure_message: "",
    bytes: 0,
    sent_bytes: 0,
    latency: 0,
    connect: 0,
  ]

  def new(label, thread_name, url) do
    %__MODULE__{
      start: :erlang.monotonic_time(:millisecond),
      time_stamp: System.os_time(:millisecond),
      label: label,
      thread_name: thread_name,
      url: url
    }
  end

  def complete(
        %RequestResult{start: start} = initial,
        latency,
        connect,
        response_code,
        response_message,
        data_type,
        success,
        failure_message,
        bytes,
        sent_bytes
      )do
    %{
      initial |
      elapsed: :erlang.monotonic_time(:millisecond) - start,
      latency: latency,
      connect: connect,
      response_code: response_code,
      response_message: response_message,
      data_type: data_type,
      success: success,
      failure_message: failure_message,
      bytes: bytes,
      sent_bytes: sent_bytes
    }
  end

end
