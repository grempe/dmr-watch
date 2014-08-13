defmodule DmrWatch.Supervisor do
  use Supervisor

  def start_link do
    :supervisor.start_link(__MODULE__, [])
  end

  def init([]) do
    children = [
      worker(GenEvent, [[name: :netwatch_event_manager]]),
      worker(GeocoderCache, []),
      worker(NetwatchRegistry, []),
      worker(Task, [ fn -> Netwatch.fetch_every end ])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    supervise(children, strategy: :one_for_one)
  end
end
