defmodule DmrWatchForwarder do
  use GenEvent

  def handle_event({:server, :time, utc_time}, parent) do
    Phoenix.Channel.broadcast("dmrwatch", "server", "time:utc_time", %{utc_time: utc_time})
    {:ok, parent}
  end

  def handle_event({:server, :status, message}, parent) do
    Phoenix.Channel.broadcast("dmrwatch", "server", "status:message", %{message: message})
    {:ok, parent}
  end

  def handle_event({:server, :geo_location_request, utc_time}, parent) do
    Phoenix.Channel.broadcast("dmrwatch", "server", "geo:location:request", %{utc_time: utc_time})
    {:ok, parent}
  end

  def handle_event(event, parent) do
    Phoenix.Channel.broadcast("dmrwatch", "server", "tx:in_progress", %{message: event})
    #send parent, event
    {:ok, parent}
  end

end
