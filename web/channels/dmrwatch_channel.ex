defmodule DmrWatch.DmrWatchChannel do
  use Phoenix.Channel

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

  # def event(socket, "new:msg", message) do
  #   broadcast socket, "new:msg", message
  #   socket
  # end
end
