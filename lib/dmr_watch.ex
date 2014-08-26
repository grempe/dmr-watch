defmodule DmrWatch do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      # Define workers and child supervisors to be supervised
      # worker(TestApp.Worker, [arg1, arg2, arg3])]
      worker(GenEvent, [[name: :dmrwatch_event_manager]]),
      worker(GeocoderCache, [], id: :geocoder_cache),
      worker(DmrMarcRadioCache, [], id: :dmr_marc_radio_cache),
      worker(NetwatchRegistry, [], id: :netwatch_registry),
      worker(Task, [ fn -> GeocoderCache.prune_every end ], id: :geocoder_cache_prune),
      worker(Task, [ fn -> DmrMarcRadioImporter.fetch_every end ], id: :dmr_marc_radio_importer_fetch_every)
#      worker(Task, [ fn -> Netwatch.fetch_every end ], id: :dmrwatch_fetch_every)
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
