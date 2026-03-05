# Use the LinuxServer.io KasmVNC Ubuntu base image
FROM ghcr.io/linuxserver/baseimage-kasmvnc:ubuntujammy

# Set an environment variable to customize the browser tab title
ENV TITLE="LM Studio Web"

# --- NEW: Expose NVIDIA GPU capabilities to the container ---
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility,graphics

# Download and install the latest LM Studio .deb package
RUN apt-get update && \
    apt-get install -y wget && \
    wget "https://lmstudio.ai/download/latest/linux/x64?format=deb" -O /tmp/lm-studio.deb && \
    apt-get install -y /tmp/lm-studio.deb && \
    rm /tmp/lm-studio.deb && \
    rm -rf /var/lib/apt/lists/*

# Tell KasmVNC to launch LM Studio on startup
# Force the autostart configuration on every container boot using s6-overlay
# This guarantees it runs even if an empty config file exists in your mapped volume
RUN mkdir -p /custom-cont-init.d && \
    echo "#!/bin/bash" > /custom-cont-init.d/99-nvidia-and-autostart && \
    echo "chmod a+rw /dev/nvidia* 2>/dev/null || true" >> /custom-cont-init.d/99-nvidia-and-autostart && \
    echo "mkdir -p /config/.config/openbox" >> /custom-cont-init.d/99-nvidia-and-autostart && \
    echo "echo 'lm-studio --no-sandbox &' > /config/.config/openbox/autostart" >> /custom-cont-init.d/99-nvidia-and-autostart && \
    echo "chown -R abc:abc /config/.config/openbox" >> /custom-cont-init.d/99-nvidia-and-autostart && \
    chmod +x /custom-cont-init.d/99-nvidia-and-autostart

    
