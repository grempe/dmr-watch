defmodule Tick do

  @doc """
  Broadcast timestamp to all connected WebSocket clients
  """
  def broadcast_time do
    # FIXME : Is time off from my watch? norcal list is also off by 15 sec. Could time on cbridge server be off by 15 seconds?
    # FIXME : :dmrwatch_event_manager should be a env var.
    :ok = GenEvent.sync_notify(:dmrwatch_event_manager, {:server, :time, Timex.DateFormat.format!(Timex.Date.local, "{ISO}")})
  end

  @doc """
  Request GeoLocation trigger for JS WebSocket clients
  """
  def request_geo_location do
    :ok = GenEvent.sync_notify(:dmrwatch_event_manager, {:server, :geo_location_request, Timex.DateFormat.format!(Timex.Date.local, "{ISO}")})
  end

end