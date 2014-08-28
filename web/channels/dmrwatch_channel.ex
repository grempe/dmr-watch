defmodule DmrWatch.DmrWatchChannel do
  use Phoenix.Channel
  require Logger

  @doc """
  Authorize socket to subscribe and broadcast events on this channel & topic

  Possible Return Values

  {:ok, socket} to authorize subscription for channel for requested topic

  {:error, socket, reason} to deny subscription/broadcast on this channel
  for the requested topic
  """
  def join(socket, "server", _message) do
    reply socket, "join", %{status: "connected"}
    {:ok, socket}
  end

  def join(socket, _private_topic, _message) do
    {:error, socket, :unauthorized}
  end

  # CLIENT SENT EVENTS
  # ##################

  def event(socket, "geo:location:response", message) do
    broadcast socket, "geo:location", message
    socket
  end

  def event(socket, "geo:location:response:error", message) do
    Logger.info "geo:location:response:error : #{message}"
    socket
  end

end
