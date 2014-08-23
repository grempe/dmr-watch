defmodule NetwatchForwarder do
  use GenEvent

  def handle_event({:status, msg}, parent) do
    Phoenix.Channel.broadcast("netwatch", "status", "server:update", msg)
    {:ok, parent}
  end

  def handle_event(event, parent) do
    Phoenix.Channel.broadcast("netwatch", "transmit", "tx:in_progress", event)
    #send parent, event
    {:ok, parent}
  end

end
