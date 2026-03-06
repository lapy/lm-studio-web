#!/usr/bin/env bash
set -e

USER_NAME="lmstudio"
DISPLAY=":1"

# Ensure we clean up any stale VNC session
su - "${USER_NAME}" -c "vncserver -kill ${DISPLAY}" >/dev/null 2>&1 || true

# Start TigerVNC without authentication (SecurityTypes None), bound only to localhost
su - "${USER_NAME}" -c "vncserver ${DISPLAY} -geometry 1920x1080 -depth 24 -SecurityTypes None"

# Start noVNC (websockify) to expose the VNC session over WebSockets on port 3000
if command -v websockify >/dev/null 2>&1; then
  exec websockify --web /usr/share/novnc/ 0.0.0.0:3000 localhost:5901
elif [ -x /usr/share/novnc/utils/novnc_proxy ]; then
  exec /usr/share/novnc/utils/novnc_proxy --vnc localhost:5901 --listen 3000
else
  echo "noVNC/websockify not found in expected locations." >&2
  exit 1
fi

