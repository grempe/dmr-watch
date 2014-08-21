defmodule DmrWatch.Router do
  use Phoenix.Router
  use Phoenix.Router.Socket, mount: "/ws"

  plug Plug.Static, at: "/static", from: :dmr_watch
  get "/", DmrWatch.PageController, :index, as: :page

  channel "netwatch", DmrWatch.NetwatchChannel

end
