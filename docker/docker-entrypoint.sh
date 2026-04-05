#!/bin/bash

# Clean up stale X lock files from previous runs
rm -f /tmp/.X99-lock /tmp/.X11-unix/X99

# Start virtual framebuffer (required by Proton/Wine)
Xvfb :99 -screen 0 1024x768x16 &
sleep 1

chown -R steam:steam /app
chmod a+x /app/start.sh
exec gosu steam /app/start.sh
