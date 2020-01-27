defmodule Perf.LoadGenerator.Conf do

  defstruct [:method, :path, :headers, :body]

  def new(method, path) do
    %Perf.Model.Request{method: method, path: path, headers: [], body: ""}
  end

end
