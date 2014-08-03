use Mix.Config

config :phoenix, DmrWatch.Router,
  port: System.get_env("PORT") || 4001,
  ssl: false,
  code_reload: false,
  cookies: true,
  consider_all_requests_local: true,
  session_key: "_dmr_watch_key",
  session_secret: "ODU1U&Q40%R01T2+9B(QFH$*XGI#Y^(^R_OIWP&CR4#N2__TWJ*=_8XE$U+SY6WENSM3D77"

config :phoenix, :logger,
  level: :debug


