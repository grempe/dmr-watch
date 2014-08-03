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
  session_secret: "ODU1U&Q40%R01T2+9B(QFH$*XGI#Y^(^R_OIWP&CR4#N2__TWJ*=_8XE$U+SY6WENSM3D77"

config :phoenix, :logger,
  level: :error


# Import environment specific config. Note, this must remain at the bottom of
# this file to properly merge your previous config entries.
import_config "#{Mix.env}.exs"
