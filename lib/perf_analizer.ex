defmodule PerfAnalizer do
  @moduledoc """
  Documentation for PerfAnalizer.
  """

  @doc """
  Hello world.

  ## Examples

      iex> PerfAnalizer.hello()
      :world

  """
  def testErrs(fun) do
    try do
      fun.()
      :no_error
    catch
      value -> IO.puts(inspect(value)) # Solo captura los :throw
               :primera_captura
      :error, value = %RuntimeError{} -> IO.puts(inspect(value))
                       :is_error
      :error, value -> IO.puts(inspect(value))
                       :is_naked_error
      :exit, value -> IO.puts(inspect(value))
                      :is_exit
      :throw, value -> IO.puts(inspect(value))
                       :is_throw
    end
end

  def testErrs2(fun) do
    try do
      fun.()
      :no_error
    rescue #Solo captura :error, deja pasar :exit y :throw
      x -> IO.puts(inspect(x)) #Hace match con el valor
    end

end

end