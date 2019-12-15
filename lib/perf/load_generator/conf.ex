defmodule Perf.LoadGenerator.Conf do

  defstruct [:method, :path, :headers, :body]

  def new(method, path, headers, body) do
    %Perf.LoadGenerator.Conf{method: method, path: path, headers: headers, body: body}
  end

  def new(method, path, headers) do
    new(method, path, headers, "")
  end

  def new(method, path) do
    new(method, path, [])
  end

end
