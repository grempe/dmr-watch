defmodule NetwatchForwarder do
  use GenEvent
  use Jazz

  def handle_event(event, parent) do
    Phoenix.Channel.broadcast "netwatch", "transmit", "tx:in_progress", JSON.encode!(event)
    #send parent, event
    {:ok, parent}
  end

end
