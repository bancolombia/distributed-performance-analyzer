defmodule PartialResult do
  defstruct [
    success_count: 0,
    http_count: 0,
    total_count: 0,
    fail_http_count: 0,
    protocol_error_count: 0,
    invocation_error_count: 0,
    error_conn_count: 0,
    nil_conn_count: 0,
    success_mean_latency: 0,
    http_mean_latency: 0,
    http_max_latency: 0,
    success_max_latency: 0,
    concurrency: 1,
    times: [],
    p90: 0,
  ]

  def new, do: %__MODULE__{}

  def combine(partial0 = %__MODULE__{}, partial1 = %__MODULE__{}) do
    %__MODULE__{
      success_count: partial0.success_count + partial1.success_count,
      http_count: partial0.http_count + partial1.http_count,
      total_count: partial0.total_count + partial1.total_count,
      fail_http_count: partial0.fail_http_count + partial1.fail_http_count,
      protocol_error_count: partial0.protocol_error_count + partial1.protocol_error_count,
      invocation_error_count: partial0.invocation_error_count + partial1.invocation_error_count,
      error_conn_count: partial0.error_conn_count + partial1.error_conn_count,
      nil_conn_count: partial0.nil_conn_count + partial1.nil_conn_count,
      success_mean_latency: partial0.success_mean_latency + partial1.success_mean_latency,
      http_mean_latency: partial0.http_mean_latency + partial1.http_mean_latency,
      http_max_latency: max(partial0.http_max_latency, partial1.http_max_latency),
      success_max_latency: max(partial0.success_max_latency, partial1.success_max_latency),
      concurrency: partial0.concurrency + partial1.concurrency,
      times: Enum.concat(partial0.times, partial1.times)
    }
  end

  def calculate(result_list) do
    Enum.reduce(result_list, new(), fn item, acc -> calculate(acc, item) end)
  end

  defp calculate(partial = %__MODULE__{}, {_time, {:ok, latency}}) do
    latency = latency / 1000
    %{partial |
      success_count: partial.success_count + 1,
      http_count: partial.http_count + 1,
      total_count: partial.total_count + 1,
      success_mean_latency: partial.success_mean_latency + latency,
      http_mean_latency: partial.http_mean_latency + latency,
      success_max_latency: max(latency, partial.success_max_latency),
      http_max_latency: max(latency, partial.http_max_latency),
      times: [latency | partial.times]
    }
  end

  defp calculate(partial = %__MODULE__{}, {0, :invocation_error}) do
    %{partial |
      total_count: partial.total_count + 1,
      invocation_error_count: partial.invocation_error_count + 1
    }
  end

  defp calculate(partial = %__MODULE__{}, {_time, {:nil_conn, reason}}) do
    %{partial |
      total_count: partial.total_count + 1,
      nil_conn_count: partial.nil_conn_count + 1
    }
  end

  defp calculate(partial = %__MODULE__{}, {_time, {:error_conn, reason}}) do
    %{partial |
      total_count: partial.total_count + 1,
      error_conn_count: partial.error_conn_count + 1
    }
  end

  defp calculate(partial = %__MODULE__{}, {_time, {:protocol_error, reason}}) do
    %{partial |
      total_count: partial.total_count + 1,
      protocol_error_count: partial.protocol_error_count + 1
    }
  end

  defp calculate(partial = %__MODULE__{}, {_time, {{:fail_http, status_code}, latency}}) do
    latency = latency / 1000
    %{partial |
      total_count: partial.total_count + 1,
      http_count: partial.http_count + 1,
      fail_http_count: partial.fail_http_count + 1,
      http_mean_latency: partial.http_mean_latency + latency,
      http_max_latency: max(latency, partial.http_max_latency)
    }
  end
  
  def calculate_p90(partial = %__MODULE__{}) do
    case Enum.count(partial.times) do
      0 ->
        partial
      _ -> 
        sorted_times = Enum.sort(partial.times)
        n = length(sorted_times)
        index = 0.90 * n
    
        p90_calc = case is_round?(index) do
          true ->
            x = Enum.at(sorted_times, trunc(index))
            xp = Enum.at(sorted_times, trunc(index)+1)
            (x + xp) / 2 
              |> IO.inspect
              |> round
          false -> 
            index = round(index)
            Enum.at(sorted_times, index)
        end
        |> round
    
        %{partial |
          p90: p90_calc,
          times: [],
        }
    end
  end

  defp is_round?(n) do
    Float.floor(n) == n
  end

end
