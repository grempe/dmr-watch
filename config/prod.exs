use Mix.Config

config :phoenix, DmrWatch.Router,
  port: System.get_env("PORT"),
  ssl: false,
  code_reload: false,
  cookies: true,
  session_key: "_dmr_watch_key",
  session_secret: "ODU1U&Q40%R01T2+9B(QFH$*XGI#Y^(^R_OIWP&CR4#N2__TWJ*=_8XE$U+SY6WENSM3D77"

config :phoenix, :logger,
  level: :error

