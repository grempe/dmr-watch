defmodule DmrWatch do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    # The following was an idea by chrismccord.  start/2 is expected to return {:ok, pid}
    # or things will blow up.  I needed to register the GenEvent handler after the supervisor
    # started so that there is a process to register with.  Then return the {:ok, pid} at
    # the end.
    {:ok, pid} = DmrWatch.Supervisor.start_link
    :ok = GenEvent.add_handler(:netwatch_event_manager, NetwatchForwarder, self())
    {:ok, pid}
  end
end
