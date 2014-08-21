defmodule DmrWatch.Router do
  use Phoenix.Router
  use Phoenix.Router.Socket, mount: "/ws"

  get "/", DmrWatch.PageController, :index, as: :page

  channel "netwatch", DmrWatch.NetwatchChannel

end
