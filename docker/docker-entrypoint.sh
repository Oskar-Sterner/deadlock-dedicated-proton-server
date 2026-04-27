#!/bin/bash

# Clean up stale X lock files from previous runs
rm -f /tmp/.X99-lock /tmp/.X11-unix/X99

# Start virtual framebuffer (required by Proton/Wine)
# Use minimal resolution and color depth — the server doesn't display
# anything, Xvfb just needs to exist for Wine/Proton to initialize.
Xvfb :99 -screen 0 640x480x8 -nolisten tcp -nolisten unix +extension GLX &
sleep 1

# Only chown the launch script. A recursive chown on /app would force
# every file in an overlayfs lowerdir to copy up to the upperdir,
# multiplying disk usage by the size of the game install (~37 GB).
[ -f /app/start.sh ] && chown steam:steam /app/start.sh
chmod a+x /app/start.sh
exec gosu steam /app/start.sh
