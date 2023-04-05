defmodule DistributedPerformanceAnalyzer.Domain.UseCase.AppRegistryUseCase do

  @moduledoc """
  Use case app registry

   Track processes
   Search process, registry process and topics of process
   Assign key-value to process
  """


  ## TODO Add functions to business logic app

  def start_link do
    Registry.start_link(keys: :unique, name: __MODULE__) #returns a PID with name of module
  end

  def via_tuple(key) do
    {:via, Registry, {__MODULE__, key}}
  end

  def child_spec(_) do
    Supervisor.child_spec(Registry, id: __MODULE__, start: {__MODULE__, :start_link, []})
  end
end
