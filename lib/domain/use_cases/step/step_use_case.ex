defmodule DistributedPerformanceAnalyzer.Domain.UseCase.Step.StepUseCase do
  @moduledoc """
  Step use case
  """
  alias DistributedPerformanceAnalyzer.Domain.Model.{Config.Step, Config.Strategy, Scenario, User}
  alias DistributedPerformanceAnalyzer.Domain.UseCase.User.UserUseCase

  use GenServer
  require Logger

  @supervisor_name Step.Supervisor

  def start_link(%Step{} = step) do
    Logger.debug("Scenario #{step.scenario.name} - starting step #{step.number}...")
    GenServer.start_link(__MODULE__, step, name: __MODULE__)
  end

  @impl true
  def init(%Step{scenario: scenario, number: step_number}) do
    with {:ok, _} <- start_step(scenario, step_number) do
      {:ok, nil}
    else
      {:error, reason} ->
        Logger.error(reason)
        {:stop, reason}
    end
  end

  defp start_step(_, 0), do: {:error, :invalid_step_number}

  defp start_step(%Scenario{strategy: strategy} = scenario, step_number) when step_number > 0 do
    concurrency = get_concurrency(strategy, step_number)
    user_config = get_user_config(scenario)

    Logger.info(
      "Scenario #{scenario.name} - starting step #{step_number} with #{concurrency} users..."
    )

    children = [
      :poolboy.child_spec(
        :worker,
        get_pool_config(concurrency),
        user_config
      )
    ]

    opts = [strategy: :one_for_one, name: @supervisor_name]
    Supervisor.start_link(children, opts)
  end

  defp get_concurrency(
         %Strategy{initial: initial, increment: increment},
         step_number
       ) do
    case initial do
      0 -> increment * step_number
      _ -> initial + increment * (step_number - 1)
    end
  end

  defp get_user_config(%Scenario{} = step), do: User.new(step)

  defp get_pool_config(concurrency),
    do: [
      name: {:local, :worker},
      worker_module: UserUseCase,
      size: concurrency,
      max_overflow: 0
    ]

  #  TODO: remove
  def get_concurrency(%Step{number: number, scenario: scenario}) do
    scenario.strategy.increment * number
  end

  def get_name(%Step{number: number, scenario: scenario}) do
    "#{scenario.name} - step: #{number}"
  end
end
