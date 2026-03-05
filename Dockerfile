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
    wget --show-error "https://lmstudio.ai/download/latest/linux/x64?format=deb" -O /tmp/lm-studio.deb && \
    apt-get install -y /tmp/lm-studio.deb && \
    rm /tmp/lm-studio.deb && \
    rm -rf /var/lib/apt/lists/*

# Tell KasmVNC to launch LM Studio on startup
RUN mkdir -p /root/defaults && \
    echo "lm-studio --no-sandbox" > /root/defaults/autostart
