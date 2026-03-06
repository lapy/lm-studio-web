FROM nvidia/cuda:12.9.0-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive \
    NVIDIA_VISIBLE_DEVICES=all \
    NVIDIA_DRIVER_CAPABILITIES=compute,utility,graphics

# Install X11, a lightweight desktop, VNC server, noVNC, and LM Studio dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      wget curl ca-certificates \
      dbus-x11 \
      xfce4 xfce4-terminal \
      tigervnc-standalone-server \
      novnc websockify \
      x11-xserver-utils \
      fonts-dejavu-core \
      sudo \
      gnupg \
      # Common Electron/Chromium GUI deps for LM Studio
      libnss3 libxss1 libasound2 \
      libatk1.0-0 libatk-bridge2.0-0 libcups2 \
      libdrm2 libxkbcommon0 libxcomposite1 libxrandr2 \
      libxdamage1 libxfixes3 libpango-1.0-0 libcairo2 && \
    wget "https://lmstudio.ai/download/latest/linux/x64?format=deb" -O /tmp/lm-studio.deb && \
    apt-get install -y /tmp/lm-studio.deb && \
    rm /tmp/lm-studio.deb && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create a non-root user to run the desktop session and LM Studio
RUN useradd -m -s /bin/bash lmstudio && \
    echo "lmstudio ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/010-lmstudio-nopasswd && \
    chmod 0440 /etc/sudoers.d/010-lmstudio-nopasswd

# Configure the VNC session startup for the lmstudio user
USER lmstudio
ENV HOME=/home/lmstudio

RUN mkdir -p "$HOME/.vnc" && \
    echo "#!/bin/bash" > "$HOME/.vnc/xstartup" && \
    echo "xrdb \$HOME/.Xresources" >> "$HOME/.vnc/xstartup" && \
    echo "startxfce4 &" >> "$HOME/.vnc/xstartup" && \
    echo "lm-studio --no-sandbox &" >> "$HOME/.vnc/xstartup" && \
    chmod +x "$HOME/.vnc/xstartup" && \
    # Prepare a single LM Studio data root that can be volume-mounted
    mkdir -p "$HOME/lm-data/.lmstudio" "$HOME/lm-data/.config/LMStudio" "$HOME/lm-data/.cache/lm-studio" && \
    ln -s "$HOME/lm-data/.lmstudio" "$HOME/.lmstudio" && \
    mkdir -p "$HOME/.config" "$HOME/.cache" && \
    ln -s "$HOME/lm-data/.config/LMStudio" "$HOME/.config/LMStudio" && \
    ln -s "$HOME/lm-data/.cache/lm-studio" "$HOME/.cache/lm-studio"

USER root

# Copy startup script that launches VNC + noVNC and keeps the container running
COPY start-lmstudio-vnc.sh /usr/local/bin/start-lmstudio-vnc.sh
RUN chmod +x /usr/local/bin/start-lmstudio-vnc.sh

EXPOSE 3000 1234

CMD ["/usr/local/bin/start-lmstudio-vnc.sh"]
