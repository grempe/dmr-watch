# This file is responsible for configuring your application
use Mix.Config

# Note this file is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project.

config :phoenix, DmrWatch.Router,
  port: System.get_env("PORT"),
  ssl: false,
  code_reload: false,
  static_assets: true,
  cookies: true,
  session_key: "_dmr_watch_key",
  session_secret: "0EE=TT21H0JO99ZRU0W@J9_$&2%HG1GNK(U3YGOE5&#@JE#4)*9$12=3U292)5+P!G$W21HI"

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]



# Import environment specific config. Note, this must remain at the bottom of
# this file to properly merge your previous config entries.
import_config "#{Mix.env}.exs"
