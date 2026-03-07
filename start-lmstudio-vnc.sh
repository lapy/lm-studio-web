#!/usr/bin/env bash
set -e

USER_NAME="lmstudio"
export DISPLAY=":1"

# Ensure NVIDIA/CUDA library paths are discoverable by child processes.
# The NVIDIA container runtime bind-mounts driver libs at runtime; running
# ldconfig refreshes the cache so all processes find them without LD_LIBRARY_PATH.
export LD_LIBRARY_PATH="/usr/local/cuda/lib64:/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-}"
export PATH="/usr/local/cuda/bin:${PATH}"
ldconfig 2>/dev/null || true

# LM Studio resolves its data directory relative to /config. Create the
# symlink at runtime (as root) so the lmstudio user can write to it.
[ -L /config ] || ln -sfn "/home/${USER_NAME}" /config

# Detect which CUDA GPU indices are actually usable (some GPUs may be
# claimed by the display server and return cudaError on init). LM Studio
# aborts the entire survey if any GPU fails, so expose only working ones.
CUDA_WORKING=$(python3 - <<'EOF' 2>/dev/null
import ctypes
gpus = []
try:
    lib = ctypes.CDLL("libcudart.so.12")
    n = ctypes.c_int()
    if lib.cudaGetDeviceCount(ctypes.byref(n)) == 0:
        for i in range(n.value):
            if lib.cudaSetDevice(i) == 0:
                gpus.append(str(i))
except Exception:
    pass
print(",".join(gpus))
EOF
)
if [ -n "${CUDA_WORKING}" ]; then
    export CUDA_VISIBLE_DEVICES="${CUDA_WORKING}"
    echo "CUDA_VISIBLE_DEVICES=${CUDA_VISIBLE_DEVICES}"
fi

# Grant access to all NVIDIA device nodes and create the XDG runtime dir.
chmod a+rw /dev/nvidia* 2>/dev/null || true
mkdir -p "/tmp/runtime-${USER_NAME}" && chown "${USER_NAME}:" "/tmp/runtime-${USER_NAME}"

# Kill any stale VNC session, then start a fresh one.
runuser -u "${USER_NAME}" -- vncserver -kill ${DISPLAY} >/dev/null 2>&1 || true
runuser -u "${USER_NAME}" -- vncserver ${DISPLAY} -geometry 1920x1080 -depth 24 -SecurityTypes None

# Wait for the XFCE desktop + D-Bus session to initialise, then launch
# LM Studio. Passing the session D-Bus address lets LM Studio's forked
# worker processes communicate correctly.
(sleep 7 && \
  XFCE_PID=$(pgrep xfce4-session | head -1) && \
  DBUS_ADDR=$(cat "/proc/${XFCE_PID}/environ" 2>/dev/null \
              | tr '\0' '\n' | grep '^DBUS_SESSION_BUS_ADDRESS=' \
              | head -1 | cut -d= -f2-) && \
  runuser -u "${USER_NAME}" -- env \
    DISPLAY="${DISPLAY}" \
    XDG_RUNTIME_DIR="/tmp/runtime-${USER_NAME}" \
    DBUS_SESSION_BUS_ADDRESS="${DBUS_ADDR}" \
    CUDA_VISIBLE_DEVICES="${CUDA_VISIBLE_DEVICES:-}" \
    lm-studio --no-sandbox) &

# Start noVNC (websockify) to expose the VNC session over WebSockets on port 3000
if command -v websockify >/dev/null 2>&1; then
  exec websockify --web /usr/share/novnc/ 0.0.0.0:3000 localhost:5901
elif [ -x /usr/share/novnc/utils/novnc_proxy ]; then
  exec /usr/share/novnc/utils/novnc_proxy --vnc localhost:5901 --listen 3000
else
  echo "noVNC/websockify not found in expected locations." >&2
  exit 1
fi
