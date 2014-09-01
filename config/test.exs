use Mix.Config

config :phoenix, DmrWatch.Router,
  port: System.get_env("PORT") || 4001,
  ssl: false,
  cookies: true,
  session_key: "_dmr_watch_key",
  session_secret: "B_!DKN8RP6YZ@%LGZ(0&9(*SQ&@DUV^H!D*W230))9IGD3$NF1LLICJ_&ZL%PEU7)@^N915"

config :phoenix, :code_reloader,
  enabled: true

config :logger, :console,
  level: :debug
