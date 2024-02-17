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
  def before_construct(%{method: method} = input) when is_binary(method) do
    case method do
      method when method in @string_allowed_methods ->
        {:ok, %{input | method: String.downcase(method) |> String.to_atom()}}

      _ ->
        {:error, {:constructor, %{method: "Invalid HTTP #{inspect(method)} method!"}}}
    end
  end

  @impl Constructor
  def before_construct(%{method: method} = input) when is_atom(method) do
    case method do
      method when method in @atoms_allowed_methods ->
        {:ok, input} |> IO.inspect(label: "before_construct")

      _ ->
        {:error, {:constructor, %{method: "Invalid HTTP #{inspect(method)} method!"}}}
    end
  end
end
