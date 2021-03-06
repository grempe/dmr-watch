defmodule DmrWatch do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # run some processes every interval
    {:ok, _} = :timer.apply_interval(1_000, Tick, :broadcast_time, [])          # 1 second
    {:ok, _} = :timer.apply_interval(1_000, Netwatch, :fetch, [])               # 1 second
    {:ok, _} = :timer.apply_interval(10_000, Tick, :request_geo_location, [])   # 10 seconds
    {:ok, _} = :timer.apply_interval(600_000, Cache, :prune, [])                # 600_000 = 10 min
    {:ok, _} = :timer.apply_interval(900_000, DmrMarcRadioImporter, :fetch, []) # 900_000 = 15 min

    children = [
      # Define workers and child supervisors to be supervised
      # worker(TestApp.Worker, [arg1, arg2, arg3])
      worker(GenEvent, [[name: :dmrwatch_event_manager]]),
      worker(Cache, [], id: :dmrwatch_cache),
    ]

    opts = [strategy: :one_for_one, max_restarts: 1000, name: DmrWatch.Supervisor]

    # The following was an idea by chrismccord.  start/2 is expected to return {:ok, pid}
    # or things will blow up.  I needed to register the GenEvent handler after the supervisor
    # started so that there is a process to register with.  Then return the {:ok, pid} at
    # the end.
    {:ok, pid} = Supervisor.start_link(children, opts)
    :ok = GenEvent.add_handler(:dmrwatch_event_manager, DmrWatchForwarder, self())
    {:ok, pid}
  end
end
