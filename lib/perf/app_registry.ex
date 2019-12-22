defmodule Perf.AppRegistry do
  @moduledoc false

  def start_link(_) do
    Registry.start_link(keys: :unique, name: Perf.AppRegistry)
  end

end
