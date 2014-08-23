use Mix.Config

config :phoenix, DmrWatch.Router,
  port: System.get_env("PORT"),
  ssl: false,
  host: "dmr-watch.rempe.us",
  cookies: true,
  session_key: "_dmr_watch_key",
  session_secret: "0EE=TT21H0JO99ZRU0W@J9_$&2%HG1GNK(U3YGOE5&#@JE#4)*9$12=3U292)5+P!G$W21HI"

config :logger, :console,
  level: :info,
  metadata: [:request_id]

