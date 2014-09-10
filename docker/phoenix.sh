#!/bin/sh
# runit script:
# must be chmod +x
# `/sbin/setuser elixir` runs the given command as the user `elixir`.
# If you omit that part, the command will be run as root.
cd /home/elixir/app
exec /sbin/setuser elixir /usr/local/bin/elixir -pa _build/prod/consolidated -S mix phoenix.start >>/var/log/phoenix.log 2>&1
