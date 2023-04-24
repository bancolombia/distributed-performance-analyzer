defmodule DistributedPerformanceAnalyzer.Infrastructure.Adapters.RestConsumer.ApiRest.ApiRestAdapter do
  alias DistributedPerformanceAnalyzer.Config.ConfigHolder
  # alias DistributedPerformanceAnalyzer.Domain.Model.ApiRest
  # alias DistributedPerformanceAnalyzer.Infrastructure.Adapters.RestConsumer.ApiRest.Data.ApiRestRequest

  def get() do
    %{api_rest_url: url} = ConfigHolder.conf()

    with {:ok, %Finch.Response{body: body}} <- Finch.build(:get, url) |> Finch.request(HttpFinch),
         {:ok, response} <- Poison.decode(body) do
      {:ok, response}
    end
  end

  def post(body) do
    %{api_rest_url: url} = ConfigHolder.conf()
    headers = [{"Content-Type", "application/json"}]

    # body = struct(ApiRestRequest, body)

    with {:ok, request} <- Poison.encode(body),
         {:ok, %Finch.Response{body: body, status: _}} <-
           Finch.build(:post, url, headers, request) |> Finch.request(HttpFinch) do
      # Poison.decode(body, as: %ApiRest{})
      Poison.decode(body)
    end
  end
end
