defmodule DmrWatch.Router do
  use Phoenix.Router

  plug Plug.Static, at: "/static", from: :dmr_watch
  get "/", DmrWatch.PageController, :index, as: :page
end
