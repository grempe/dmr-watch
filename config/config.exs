# This file is responsible for configuring your application
use Mix.Config

# Note this file is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project.

config :phoenix, DmrWatch.Router,
  port: System.get_env("PORT"),
  ssl: false,
  static_assets: true,
  cookies: true,
  session_key: "_dmr_watch_key",
  session_secret: "B_!DKN8RP6YZ@%LGZ(0&9(*SQ&@DUV^H!D*W230))9IGD3$NF1LLICJ_&ZL%PEU7)@^N915",
  catch_errors: true,
  debug_errors: false,
  error_controller: DmrWatch.PageController

config :phoenix, :code_reloader,
  enabled: false

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. Note, this must remain at the bottom of
# this file to properly merge your previous config entries.
import_config "#{Mix.env}.exs"
