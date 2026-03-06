#!/usr/bin/env bash
set -e

USER_NAME="lmstudio"
export DISPLAY=":1"

# Ensure NVIDIA/CUDA library paths are discoverable by child processes.
# The NVIDIA container runtime mounts driver libs here; llama.cpp inside
# LM Studio needs them to find the GPU.
export LD_LIBRARY_PATH="/usr/local/cuda/lib64:/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-}"
export PATH="/usr/local/cuda/bin:${PATH}"

# Ensure we clean up any stale VNC session and grant GPU device access
chmod a+rw /dev/nvidia* 2>/dev/null || true
runuser -u "${USER_NAME}" -- vncserver -kill ${DISPLAY} >/dev/null 2>&1 || true

# Start TigerVNC without authentication (SecurityTypes None), bound only to localhost
# runuser preserves the environment (DISPLAY, LD_LIBRARY_PATH, NVIDIA_* vars)
runuser -u "${USER_NAME}" -- vncserver ${DISPLAY} -geometry 1920x1080 -depth 24 -SecurityTypes None

# Wait for the desktop to initialise, then launch LM Studio in the background
(sleep 5 && runuser -u "${USER_NAME}" -- lm-studio --no-sandbox) &

# Start noVNC (websockify) to expose the VNC session over WebSockets on port 3000
if command -v websockify >/dev/null 2>&1; then
  exec websockify --web /usr/share/novnc/ 0.0.0.0:3000 localhost:5901
elif [ -x /usr/share/novnc/utils/novnc_proxy ]; then
  exec /usr/share/novnc/utils/novnc_proxy --vnc localhost:5901 --listen 3000
else
  echo "noVNC/websockify not found in expected locations." >&2
  exit 1
fi
