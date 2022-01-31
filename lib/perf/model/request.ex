defmodule Perf.Model.Request do
  @moduledoc false

  defstruct [:method, :path, :headers, :body, :url, :item]

end
