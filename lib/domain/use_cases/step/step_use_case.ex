defmodule DistributedPerformanceAnalyzer.Domain.UseCase.Step.StepUseCase do
  @moduledoc """
  Step use case
  """
  alias DistributedPerformanceAnalyzer.Domain.Model.{Config.Step, Config.Strategy, Scenario, User}
  alias DistributedPerformanceAnalyzer.Domain.UseCase.User.UserUseCase

  use GenServer
  require Logger

  def start_link(%Step{scenario: scenario, number: step_number} = step) do
    Logger.debug("Scenario #{scenario.name} - Starting step #{step_number}...")
    GenServer.start_link(__MODULE__, step, name: get_process_name(scenario.name, step_number))
  end

  @impl true
  def init(%Step{scenario: scenario, number: step_number}) do
    with {:ok, _} <- start_step(scenario, step_number) do
      {:ok, nil}
    else
      {:error, reason} ->
        Logger.error(inspect(reason))
        {:stop, "Error starting step #{step_number} for scenario #{scenario.name}"}
    end
  end

  defp start_step(_, 0), do: {:error, :invalid_step_number}

  defp start_step(%Scenario{strategy: strategy} = scenario, step_number) when step_number > 0 do
    concurrency = get_concurrency(strategy, step_number)
    user_config = get_user_config(scenario)

    Logger.info(
      "Scenario #{scenario.name} - Starting step #{step_number} with #{concurrency} users..."
    )

    children =
      [
        :poolboy.child_spec(
          :worker,
          get_pool_config(scenario.name, concurrency),
          user_config
        )
      ]
      |> IO.inspect()

    opts =
      [strategy: :one_for_one, name: get_pool_name(scenario.name, step_number)]

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

  defp get_user_config(%Scenario{} = step) do
    {:ok, user} = User.new(step)
    user
  end

  defp get_pool_config(scenario_name, concurrency),
    do: [
      name: {:local, String.to_atom("#{scenario_name}_worker")},
      worker_module: UserUseCase,
      size: concurrency,
      max_overflow: 0
    ]

  defp get_pool_name(scenario_name, step_number),
    do: String.to_atom("#{get_process_name(scenario_name, step_number)}_pool")

  defp get_process_name(scenario_name, step_number),
    do: String.to_atom("#{scenario_name}_scenario_step_#{step_number}")

  #  TODO: remove
  def get_concurrency(%Step{number: number, scenario: scenario}) do
    scenario.strategy.increment * number
  end

  def get_name(%Step{number: number, scenario: scenario}) do
    "#{scenario.name} - step: #{number}"
  end
end
