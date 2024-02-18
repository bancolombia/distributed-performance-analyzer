defmodule DistributedPerformanceAnalyzer.Domain.Model.Config.Request do
  use Constructor

  @moduledoc """
  Request model
  """

  @string_allowed_methods ["HEAD", "GET", "DELETE", "TRACE", "OPTIONS", "POST", "PUT", "PATCH"]
  @atoms_allowed_methods [:head, :get, :delete, :trace, :options, :post, :put, :patch]

  constructor do
    field(:url, String.t(), constructor: &is_string/1)
    field(:method, :atomics, constructor: &is_atom/1)
    field(:headers, :lists, constructor: &is_list/1)
    field(:body, :any)
    field(:params, :lists, constructor: &is_list/1, default: [], enforce: false)
    field(:timeout, :integer, constructor: &is_integer/1, default: 100_000, enforce: false)
    field(:ssl, :boolean, constructor: &is_boolean/1, default: true, enforce: false)
  end

  @impl Constructor
  def before_construct(%__MODULE__{} = input), do: {:ok, input}

  @impl Constructor
  def before_construct(%{method: method, headers: headers} = input) do
    with {:ok, fix_method} <- parse_method(method),
         {:ok, fix_headers} <- parse_headers(headers) do
      {:ok, %{input | method: fix_method, headers: fix_headers}}
    else
      {:error, reason} -> {:error, {:constructor, %{method: reason}}}
    end
  end

  defp parse_method(method) do
    case method do
      method when is_binary(method) and method in @string_allowed_methods ->
        {:ok, String.downcase(method) |> String.to_atom()}

      method when is_atom(method) and method in @atoms_allowed_methods ->
        {:ok, method}

      _ ->
        {:error, "Invalid HTTP #{inspect(method)} method!"}
    end
  end

  defp parse_headers(headers) when is_list(headers) do
    {:ok,
     Enum.map(headers, fn
       {key, value} when is_binary(key) -> {key, value}
       {key, value} when is_atom(key) -> {Atom.to_string(key), value}
     end)}
  end
end
