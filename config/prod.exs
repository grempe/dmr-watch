use Mix.Config

# NOTE: To get SSL working, you will need to set:
#
#     ssl: true,
#     keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
#     certfile: System.get_env("SOME_APP_SSL_CERT_PATH"),
#
# Where those two env variables point to a file on disk
# for the key and cert

config :phoenix, DmrWatch.Router,
  port: System.get_env("PORT"),
  ssl: false,
  host: "dmr-watch.rempe.us",
  cookies: true,
  session_key: "_dmr_watch_key",
  session_secret: "B_!DKN8RP6YZ@%LGZ(0&9(*SQ&@DUV^H!D*W230))9IGD3$NF1LLICJ_&ZL%PEU7)@^N915"

config :logger, :console,
  level: :info,
  metadata: [:request_id]

