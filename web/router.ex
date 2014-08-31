defmodule DmrWatch.Router do
  use Phoenix.Router
  use Phoenix.Router.Socket, mount: "/ws"

  get "/", DmrWatch.PageController, :index, as: :pages

  channel "dmrwatch", DmrWatch.DmrWatchChannel

end
