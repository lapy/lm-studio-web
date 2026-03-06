## lm-studio-web

This image runs **LM Studio** with GPU acceleration inside a container based on the official **NVIDIA CUDA 12.9 runtime** image, and exposes the desktop via a **browser-accessible VNC session (no password)** using TigerVNC + noVNC.

### Building the image

```bash
docker build -t lm-studio-web .
```

### Running with GPU access

Make sure you have the NVIDIA container runtime configured (e.g. `nvidia-docker2` or `--gpus` support in Docker).

```bash
docker run --gpus all \
  --device /dev/nvidia-modeset \
  -p 3000:3000 \
  -p 1234:1234 \
  -v /path/on/host/lmstudio-data:/home/lmstudio/lm-data \
  --name lm-studio-web \
  lm-studio-web
```

- **`--device /dev/nvidia-modeset`**: Required for Vulkan GPU discovery. `--gpus all` only maps compute devices; LM Studio uses Vulkan to enumerate GPUs and needs this modeset device.
- **Port 3000**: noVNC web UI (VNC over WebSockets, no password).
- **Port 1234**: LM Studio API (if enabled within LM Studio settings, listening on 0.0.0.0:1234).

### Accessing LM Studio in the browser

- Open `http://localhost:3000` in your browser.
- You will see a desktop session (XFCE) with **LM Studio** automatically launched inside it.
- No VNC password or login is required; anyone who can reach the port can access the session, so only expose it on trusted networks or behind a reverse proxy.

### Notes

- The container is based on `nvidia/cuda:12.9.0-runtime-ubuntu22.04`, so CUDA libraries like `cudart` and `cublas` are available for LM Studio to discover when you run with `--gpus all`.
- The VNC server is started with security disabled (`SecurityTypes None`) and is only protected by network-level access control you configure.
- LM Studio configuration, binaries, and models are wired to live under `/home/lmstudio/lm-data` via symlinks (`~/.lmstudio`, `~/.config/LMStudio`, `~/.cache/lm-studio`), so a **single** volume mount on `/home/lmstudio/lm-data` persists all LM Studio data across container recreation.
