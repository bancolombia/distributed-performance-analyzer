defmodule DistributedPerformanceAnalyzer.Domain.UseCase.MetricsAnalyzerUseCase do
  @moduledoc """
  Metrics Analyzer use case
  """
  use GenServer
  alias DistributedPerformanceAnalyzer.Domain.Model.{ExecutionModel, RequestResult}
  alias DistributedPerformanceAnalyzer.Domain.UseCase.MetricsCollectorUseCase

  @file_system_behaviour Application.get_env(
                           :distributed_performance_analyzer,
                           :file_system_behaviour
                         )

  def compute_metrics do
    GenServer.cast(__MODULE__, :compute)
  end

  def start_link(conf) do
    GenServer.start_link(__MODULE__, conf, name: __MODULE__)
  end

  @impl true
  def init(conf) do
    {:ok, conf}
  end

  @impl true
  def handle_cast(:compute, %ExecutionModel{duration: duration}) do
    duration_segs = duration / 1000
    metrics = MetricsCollectorUseCase.get_metrics()
    steps = Map.keys(metrics)
    steps_count = Enum.count(steps)

    curve =
      Enum.map(
        steps,
        fn step ->
          # partial = IO.inspect(Map.get(metrics, step))
          step_num =
            String.split(step, "-")
            |> Enum.at(1)
            |> String.to_integer()

          partial = Map.get(metrics, step)
          throughput = partial.success_count / duration_segs
          mean_latency = partial.success_mean_latency / (partial.success_count + 0.00001)
          mean_latency_http = partial.http_mean_latency / (partial.http_count + 0.00001)

          {
            step_num,
            throughput,
            partial.concurrency,
            mean_latency,
            partial.success_max_latency,
            mean_latency_http,
            partial
          }
        end
      )

    total_success_count =
      Enum.reduce(steps, 0, fn step, acc -> Map.get(metrics, step).success_count + acc end)

    sorted_curve = Enum.sort(curve, &(elem(&1, 0) <= elem(&2, 0)))

    IO.puts("Total steps: #{steps_count}")
    IO.puts("Total success count: #{total_success_count}")
    IO.puts("Total duration: #{steps_count * duration_segs} seconds")

    IO.puts(
      "concurrency, throughput -- mean latency, p90 latency, max latency, mean http latency, http_errors, protocol_error_count, error_conn_count, nil_conn_count"
    )

    Enum.each(
      sorted_curve,
      fn {_step, throughput, concurrency, lat_total, max_latency, mean_latency_http, partial} ->
        IO.puts(
          "#{concurrency}, #{throughput} -- #{round(lat_total)}ms, #{partial.p90}ms, #{round(max_latency)}ms, #{round(mean_latency_http)}ms, #{partial.fail_http_count}, #{partial.protocol_error_count}, #{partial.error_conn_count}, #{partial.nil_conn_count}"
        )
      end
    )

    write_to_file(
      sorted_curve,
      "config/result.csv",
      "concurrency, throughput, mean latency, p90 latency, max latency",
      true,
      fn {_step, throughput, concurrency, lat_total, max_latency, _mean_latency_http, partial} ->
        "#{concurrency}, #{round(throughput)}, #{round(lat_total)}, #{partial.p90}, #{round(max_latency)}"
      end
    )

    if Application.get_env(:perf_analyzer, :jmeter_report, true) do
      generate_jmeter_report(sorted_curve)
    end

    MetricsCollectorUseCase.clean_metrics()

    {:stop, :normal, nil}
  end

  defp generate_jmeter_report(sorted_curve) do
    request_details =
      Enum.reduce(
        sorted_curve,
        [],
        fn {_, _, _, _, _, _, %{requests: list}}, current -> Enum.concat(list, current) end
      )
      |> Enum.sort(fn req_a, req_b -> req_a.time_stamp < req_b.time_stamp end)

    write_to_file(
      request_details,
      "config/jmeter.csv",
      "timeStamp,elapsed,label,responseCode,responseMessage,threadName,dataType,success,failureMessage,bytes,sentBytes,grpThreads,allThreads,URL,Latency,IdleTime,Connect",
      false,
      fn %RequestResult{
           start: start,
           time_stamp: time_stamp,
           label: label,
           thread_name: thread_name,
           grp_threads: grp_threads,
           all_threads: all_threads,
           url: url,
           elapsed: elapsed,
           response_code: response_code,
           failure_message: failure_message,
           sent_bytes: sent_bytes,
           latency: latency,
           idle_time: idle_time,
           connect: connect,
           response_headers: headers
         } ->
        "#{time_stamp},#{elapsed},#{label},#{response_code},#{response_for_code(response_code)},#{thread_name},#{data_type(headers)},#{success?(response_code)},#{with_failure(response_code, failure_message)},#{bytes(headers)},#{sent_bytes},#{grp_threads},#{all_threads},#{url},#{latency},#{idle_time},#{connect}"
      end
    )
  end

  defp write_to_file(data, file, header, print, fun) do
    @file_system_behaviour.write_to_file(data, file, header, print, fun)
  end

  defp response_for_code(status) when status >= 200 and status < 400, do: "OK"
  defp response_for_code(status), do: "ERROR"

  defp success?(status) when status >= 200 and status < 400, do: true
  defp success?(status), do: false

  defp with_failure(status, _body) when status >= 200 and status < 400, do: nil
  defp with_failure(_status, body), do: body

  defp data_type(headers) do
    case Enum.find(headers, "TEXT", fn {type, _value} -> type == "content-type" end) do
      {_header, value} -> value
      default -> default
    end
  end

  defp bytes(headers) do
    case Enum.find(headers, "TEXT", fn {type, _value} -> type == "content-length" end) do
      {_header, value} -> value
      default -> default
    end
  end
end
